import 'package:import_lint/src/lint_options.dart';
import 'package:test/test.dart';

import '../helper/generate_test_project.dart';

void runImportLintOptionsTest() {
  group('import lint options', () {
    test('not found analysis_options.yaml', () {
      final project = GenerateTestProject.ofHasNotAnalysisOptionsYaml();
      project.generate();

      final options = () => LintOptions.init(
            directoryPath: project.directoryPath,
            optionsFilePath: project.optionsPath,
          );
      ;

      expect(
        options,
        throwsA((e) => e is Exception),
      );
    });
    test('not found pubspec.yaml', () {
      final project = GenerateTestProject.ofHasNotPubspecYaml();
      project.generate();

      final options = () => LintOptions.init(
            directoryPath: project.directoryPath,
            optionsFilePath: project.optionsPath,
          );
      ;

      expect(
        options,
        throwsA((e) => e is Exception),
      );
    });
    test('load import lint options', () {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final options = LintOptions.init(
        directoryPath: project.directoryPath,
        optionsFilePath: project.optionsPath,
      );

      //expect(options.common.packageName, GenerateTestProject.packageName);
      expect(options.common.directoryPath, project.directoryPath);
      expect(options.rules.value.length, GenerateTestProject.rulesLength);
    });
  });
}
