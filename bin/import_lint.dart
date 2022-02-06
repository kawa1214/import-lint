import 'dart:io' as io;

import 'package:import_lint/import_lint.dart';
import 'package:cli_util/cli_logging.dart';

void main(List<String> arguments) async {
  try {
    final logger = Logger.standard();
    final progress = logger.progress('Analyzing');

    final rootDirectoryPath = io.Directory.current.path;

    final analyzed =
        await ImportLintAnalyze.ofInitCli(rootDirectoryPath: rootDirectoryPath);

    progress.finish(showTiming: true);

    logger.stdout('');
    logger.stdout(analyzed.output);

    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln(s);
    io.exit(1);
  }
}
