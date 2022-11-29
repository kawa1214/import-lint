import 'dart:io' as io;

import 'package:import_lint/src/infra/cli.dart' as cli;

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
