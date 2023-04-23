import 'package:import_lint/src/config/analysis_options.dart'
    show AnalysisOptions;
import 'package:test/expect.dart' show expect;
import 'package:test_reflective_loader/test_reflective_loader.dart'
    show reflectiveTest, defineReflectiveSuite, defineReflectiveTests;

import '../helper/BaseResourceProviderMixin.dart'
    show BaseResourceProviderMixin;

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsTest);
  });
}

@reflectiveTest
class AnalysisOptionsTest with BaseResourceProviderMixin {
  AnalysisOptionsTest() {
    setUp();
  }

  void test_correctFormat() {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example_rule:
      target: "package:example/target/*_target.dart"
      from: "package:example/from/*.dart"
      expect: ["package:example/target/expect.dart"]
''');

    final context = buildContext();
    final file = context.contextRoot.optionsFile!;

    final analysisOptions = AnalysisOptions.fromYaml(file);
    final options = analysisOptions.options;

    expect(options.length, 1);
    expect(options.keys, ['import_lint']);

    final importLint = options['import_lint']! as Map<String, Object>;

    expect(importLint.length, 2);
    expect(importLint.keys, ['severity', 'rules']);

    final severity = importLint['severity']! as String;
    expect(severity, 'error');

    final rules = importLint['rules']! as Map<String, Object>;
    expect(rules.length, 1);

    final exampleRule = rules['example_rule']! as Map<String, Object>;
    expect(exampleRule.length, 3);
    expect(exampleRule.keys, ['target', 'from', 'expect']);

    final exampleRuleTarget = exampleRule['target']! as String;
    expect(exampleRuleTarget, 'package:example/target/*_target.dart');

    final exampleRuleFrom = exampleRule['from']! as String;
    expect(exampleRuleFrom, 'package:example/from/*.dart');

    final exampleRuleExpect = exampleRule['expect']! as List<dynamic>;
    expect(exampleRuleExpect.length, 1);
    expect(exampleRuleExpect[0], 'package:example/target/expect.dart');
  }

  void test_empty() {
    newFile('/analysis_options.yaml', '''
''');

    final context = buildContext();
    final file = context.contextRoot.optionsFile!;

    final analysisOptions = AnalysisOptions.fromYaml(file);
    final options = analysisOptions.options;

    expect(options.length, 0);
  }
}
