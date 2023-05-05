import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollectionImpl;
import 'package:cli_util/cli_logging.dart';
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/cli/runner.dart';

void main(List<String> args) async {
  final instance = PhysicalResourceProvider.INSTANCE;

  final collection = AnalysisContextCollectionImpl(
    resourceProvider: instance,
    includedPaths: [
      instance.pathContext.normalize(
        instance.pathContext.absolute('./lib'),
      ),
    ],
  );
  final context = collection.contexts.take(1).first;

  final logger = Logger.standard();
  try {
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);
    final runner = Runner(logger, analyzer);
    final exitCode = await runner.run(args);
    exit(exitCode);
  } catch (e, s) {
    logger.write('${e.toString()}\n');
    logger.write('''
An error occurred while linting
Please report it at: github.com/kawa1214/import-lint/issues
$e
$s
''');
    exit(1);
  }
}
