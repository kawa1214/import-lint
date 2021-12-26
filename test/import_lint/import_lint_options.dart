import 'package:import_lint/src/import_lint_options.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

import '../helper/generate_test_project.dart';

void runImportLintOptionsTest() {
  group('import lint options', () {
    test('not found analysis_options.yaml', () {
      final project = GenerateTestProject.ofHasNotAnalysisOptionsYaml();
      project.generate();

      final options =
          () => ImportLintOptions.init(directoryPath: project.directoryPath);

      expect(
        options,
        throwsA((e) => e is Exception),
      );
    });
    test('not found pubspec.yaml', () {
      final project = GenerateTestProject.ofHasNotPubspecYaml();
      project.generate();

      final options =
          () => ImportLintOptions.init(directoryPath: project.directoryPath);

      expect(
        options,
        throwsA((e) => e is Exception),
      );
    });
    test('load import lint options', () {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);

      expect(options.packageName, GenerateTestProject.packageName);
      expect(options.directoryPath, project.directoryPath);
      expect(options.rules.value.length, GenerateTestProject.rulesLength);
    });
  });
}
