import 'package:import_lint/src/plugin/import_lint_rule.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLintRuleTest);
  });
}

@reflectiveTest
class ImportLintRuleTest {
  void test_importLintRule_nameMatchesLintName() {
    final rule = ImportLintRule();

    expect(rule.name, ImportLintRule.lintName);
    expect(ImportLintRule.lintName, 'import_lint');
  }

  void test_importLintRule_descriptionMentionsConfigKey() {
    final rule = ImportLintRule();

    expect(rule.description, contains('import_lint:'));
    expect(rule.description, contains('analysis_options.yaml'));
  }

  void test_importLintRule_diagnosticCodeIsLintCode() {
    final rule = ImportLintRule();

    expect(rule.diagnosticCode, same(ImportLintRule.code));
  }

  void test_importLintRule_diagnosticCodesListContainsLintCode() {
    final rule = ImportLintRule();

    expect(rule.diagnosticCodes, [ImportLintRule.code]);
  }

  void test_importLintRule_codeNameMatchesLintName() {
    expect(ImportLintRule.code.lowerCaseName, 'import_lint');
  }

  void test_importLintRule_codeProblemMessageInterpolatesRuleName() {
    expect(ImportLintRule.code.problemMessage, 'Found Import Lint Error: {0}');
  }

  void test_importLintRule_codeCorrectionMessageSuggestsRemoval() {
    expect(ImportLintRule.code.correctionMessage, 'Try removing the import.');
  }
}
