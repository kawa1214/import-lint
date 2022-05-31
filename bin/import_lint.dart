import 'dart:io' as io;

import 'package:import_lint/src/cli.dart' as cli;

void main(List<String> args) async {
  try {
    await cli.run(args);

    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln('''
An error occurred while linting
Please report it at: github.com/kawa1214/import-lint/issues
$e
$s
''');

    io.stdout.writeln(s);
    io.exit(1);
  }
}

/*
void main(List<String> args) async {
  try {
    final logger = Logger.standard();
    final progress = logger.progress('Analyzing');

    cli.run(args);

    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [p.normalize(p.absolute('./'))],
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

      for (final filePath in filePaths) {
        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          final libFilePath =
              toProjectPath(path: result.path, options: options);
          final analyzed = ImportLintAnalyze.ofFile(
            filePath: result.path,
            file: io.File(libFilePath),
            unit: result.unit,
            options: options,
          );
          errors.addAll(analyzed.issues);
        }
      }
    }

    progress.finish(showTiming: true);

    logger.stdout('');
    logger.stdout(Output(errors).output);

    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln(s);
    io.exit(1);
  }
}
*/