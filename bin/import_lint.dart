import 'dart:io' as io;

import 'package:import_lint/import_lint/import_lint_options.dart';
import 'package:import_lint/import_lint/issue.dart';

void main(List<String> arguments) {
  try {
    final rootDirectoryPath = io.Directory.current.path;
    final options = ImportLintOptions.init(directoryPath: rootDirectoryPath);

    final issues = Issues.ofInitCli(options: options);

    io.stdout.writeln(issues.output);
    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln(s);
    io.exit(1);
  }
}
