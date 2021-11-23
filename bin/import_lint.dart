import 'package:import_lint/constants/package_name.dart';
import 'package:import_lint/import_lint/issue.dart';

import 'dart:io' as io;

void main(List<String> arguments) {
  try {
    final directoryPath = io.Directory.current.path;
    final issues = Issues.ofInitCli(directoryPath: directoryPath);

    io.stdout.writeln(
      issues.output(
        directoryPath: directoryPath,
        packageName: packageNameFromPath(directoryPath),
      ),
    );
    io.exit(0);
  } catch (e) {
    io.stdout.writeln('😿' + e.toString().replaceAll('Exception: ', ''));
    io.exit(1);
  }
}
