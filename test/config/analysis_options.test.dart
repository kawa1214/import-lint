import 'dart:collection';

import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

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

  void test_analysisOptions_parseCorrectFormat() {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example_rule:
      target: "package:example/target/*_target.dart"
      from: "package:example/from/*.dart"
      except: ["package:example/target/except.dart"]
''');

    final context = buildContext();
    final file = context.contextRoot.optionsFile!;

    final analysisOptions = AnalysisOptions.fromFile(file);

    final options = analysisOptions.options;
    expect(options.length, 1);
    expect(options.keys, ['import_lint']);

    final importLint =
        options['import_lint']! as UnmodifiableMapView<String, Object>;
    expect(importLint.length, 2);
    expect(importLint.keys, ['severity', 'rules']);

    final severity = importLint['severity']! as String;
    expect(severity, 'error');

    final rules = importLint['rules']! as Map<String, Object>;
    expect(rules.length, 1);

    final exampleRule =
        rules['example_rule']! as UnmodifiableMapView<String, Object>;
    expect(exampleRule.length, 3);
    expect(exampleRule.keys, ['target', 'from', 'except']);

    final exampleRuleTarget = exampleRule['target']! as String;
    expect(exampleRuleTarget, 'package:example/target/*_target.dart');

    final exampleRuleFrom = exampleRule['from']! as String;
    expect(exampleRuleFrom, 'package:example/from/*.dart');

    final except = exampleRule['except']! as List<String>;
    expect(except.length, 1);
    expect(except[0], 'package:example/target/except.dart');
  }

  void test_analysisOptions_parseEmptyFile() {
    newFile('/analysis_options.yaml', '''
''');

    final context = buildContext();
    final file = context.contextRoot.optionsFile!;

    final analysisOptions = AnalysisOptions.fromFile(file);
    final options = analysisOptions.options;

    expect(options.length, 0);
  }

  void test_analysisOptions_parseInvalidFile() {
    expect(
      () => AnalysisOptions.fromFile(null),
      throwsA(isA<BaseException>()),
    );
  }
}
