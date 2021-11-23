import 'dart:io';

import 'package:import_lint/import_lint/import_lint_options.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

void runImportLintOptionsTest() {
  group('issues', () {
    test('issue', () {
      const packageName = 'example';

      final directoryPath = '${Directory.current.path}/example/';
      final options = ImportLintOptions.init(directoryPath: directoryPath);
      print(options.directoryPath);
      print(options.packageName);
      print(options.rules);
      print(directoryPath);

      expect(options.directoryPath, directoryPath);
      expect(options.packageName, packageName);
    });
  });
}
