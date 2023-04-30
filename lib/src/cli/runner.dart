import 'dart:io' show exit;

import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollectionImpl;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/cli/reporter.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/severity.dart';

class Runner {
  const Runner(this._logger);
  final Logger _logger;

  PhysicalResourceProvider get instance => PhysicalResourceProvider.INSTANCE;

  Future<void> run(Iterable<String> args) async {
    try {
      final progress = _logger.progress('Analyzing');

      final collection = AnalysisContextCollectionImpl(
        resourceProvider: instance,
        includedPaths: [_absoluteNormalizePath('./lib')],
      );
      final context = collection.contexts.take(1).first;

      final paths = _dartFilePaths(context);

      final analysisOptions =
          AnalysisOptions.fromFile(_analysisOptionsFile(context));
      final config = Config.fromAnalysisOptions(analysisOptions);

      final analyzer = Analyzer(config);
      final issues = await analyzer.analyzeFiles(context, paths);

      final buf = StringBuffer();
      final reporter = Reporter(config, buf);
      reporter.writeIssues(issues);
      _logger.stdout(buf.toString());

      progress.finish(showTiming: true);

      final code = _exitCode(config.severity, issues);
      exit(code);
    } catch (e, s) {
      _logger.write('${e.toString()}\n');
      _logger.write('''
An error occurred while linting
Please report it at: github.com/kawa1214/import-lint/issues
$e
$s
''');
      exit(1);
    }
  }

  int _exitCode(Severity severity, Iterable<Issue> issues) {
    final hasError = issues.length > 0 && severity == Severity.error;
    if (hasError) {
      return 1;
    }
    return 0;
  }

  Iterable<String> _dartFilePaths(DriverBasedAnalysisContext context) {
    final paths = context.contextRoot.analyzedFiles();
    return paths.where((path) => path.endsWith('.dart'));
  }

  File? _analysisOptionsFile(DriverBasedAnalysisContext context) =>
      context.contextRoot.optionsFile;

  String _absoluteNormalizePath(String path) => instance.pathContext.normalize(
        instance.pathContext.absolute(path),
      );
}
