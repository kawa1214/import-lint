import 'dart:io' as io;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:import_lint/import_lint.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  try {
    final logger = Logger.standard();
    final progress = logger.progress('Analyzing');

    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [path.normalize(path.absolute('./'))],
    );

    final errors = <ImportLintError>[];
    for (final context in collection.contexts) {
      final rootDirectoryPath = context.contextRoot.root.path;
      final options = ImportLintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFilePath: context.contextRoot.optionsFile?.path ?? '',
      );
      final filePaths =
          context.contextRoot.analyzedFiles().where((e) => e.endsWith('.dart'));
      //print(filePaths);

      for (final filePath in filePaths) {
        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          final analyzed = ImportLintAnalyze.ofFile(
            file: io.File(filePath),
            unit: result.unit,
            options: options,
          );
          errors.addAll(analyzed.issues);
        }
      }
    }

    /*
    late ImportLintOptions options;

    for (final context in collection.contexts) {
      options = ImportLintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFilePath: context.contextRoot.optionsFile!.path,
      );
    }
    final analyzed =
        await ImportLintAnalyze.ofInitCli(rootDirectoryPath: rootDirectoryPath);
		*/
    progress.finish(showTiming: true);

    logger.stdout('');
    //logger.stdout(Output(errors).output);

    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln(s);
    io.exit(1);
  }
}
