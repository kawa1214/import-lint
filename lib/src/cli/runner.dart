import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/cli/reporter.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/severity.dart';

typedef ExitCode = int;

class Runner {
  const Runner(this._logger, this._context);
  final Logger _logger;
  final DriverBasedAnalysisContext _context;

  Future<ExitCode> run(Iterable<String> args) async {
    try {
      final progress = _logger.progress('Analyzing');

      final paths = _dartFilePaths();

      final analysisOptions = AnalysisOptions.fromFile(_analysisOptionsFile());
      final config = Config.fromAnalysisOptions(analysisOptions);

      final analyzer = Analyzer(config);
      final issues = await analyzer.analyzeFiles(_context, paths);

      final buf = StringBuffer();
      final reporter = Reporter(config, buf);
      reporter.writeIssues(issues);
      _logger.write(buf.toString());

      progress.finish(showTiming: true);

      final code = _exitCode(config.severity, issues);
      return code;
    } catch (e, s) {
      _logger.write('${e.toString()}\n');
      _logger.write('''
An error occurred while linting
Please report it at: github.com/kawa1214/import-lint/issues
$e
$s
''');
      return 1;
    }
  }

  int _exitCode(Severity severity, Iterable<Issue> issues) {
    final hasError = issues.length > 0 && severity == Severity.error;
    if (hasError) {
      return 1;
    }
    return 0;
  }

  Iterable<String> _dartFilePaths() {
    final paths = _context.contextRoot.analyzedFiles();
    return paths.where((path) => path.endsWith('.dart'));
  }

  File? _analysisOptionsFile() => _context.contextRoot.optionsFile;
}
