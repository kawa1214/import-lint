import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollectionImpl;
import 'package:cli_util/cli_logging.dart';
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
  final runner = Runner(logger, context);
  final exitCode = await runner.run(args);
  exit(exitCode);
}
