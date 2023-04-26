import 'dart:collection';

import 'package:import_lint/src/config/analysis_options.dart';
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

  void test_correctFormat() {
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

    final analysisOptions = AnalysisOptions.fromYaml(file);

    final options = analysisOptions.options;
    expect(options.runtimeType, UnmodifiableMapView<String, Object>);
    expect(options.length, 1);
    expect(options.keys, ['import_lint']);

    expect(
      options['import_lint'].runtimeType,
      UnmodifiableMapView<String, Object>,
    );
    final importLint =
        options['import_lint']! as UnmodifiableMapView<String, Object>;
    expect(importLint.length, 2);
    expect(importLint.keys, ['severity', 'rules']);

    expect(importLint['severity'].runtimeType, String);
    final severity = importLint['severity']! as String;
    expect(severity, 'error');

    expect(
      importLint['rules'].runtimeType,
      UnmodifiableMapView<String, Object>,
    );
    final rules = importLint['rules']! as Map<String, Object>;
    expect(rules.length, 1);

    final exampleRule =
        rules['example_rule']! as UnmodifiableMapView<String, Object>;
    expect(exampleRule.length, 3);
    expect(exampleRule.keys, ['target', 'from', 'except']);

    expect(exampleRule['target'].runtimeType, String);
    final exampleRuleTarget = exampleRule['target']! as String;
    expect(exampleRuleTarget, 'package:example/target/*_target.dart');

    expect(exampleRule['from'].runtimeType, String);
    final exampleRuleFrom = exampleRule['from']! as String;
    expect(exampleRuleFrom, 'package:example/from/*.dart');

    expect(exampleRule['except'].runtimeType, List<String>);
    final except = exampleRule['except']! as List<String>;
    expect(except.length, 1);
    expect(except[0], 'package:example/target/except.dart');
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
