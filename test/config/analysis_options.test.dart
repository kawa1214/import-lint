import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/utils.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsTest);
  });
}

@reflectiveTest
class AnalysisOptionsTest with ResourceProviderMixin {
  AnalysisOptionsTest() {
    setUp();
  }
  Folder get _sdkRoot => newFolder('/sdk');

  String get _includedPaths => absoluteNormalizedPath('./');

  DriverBasedAnalysisContext _buildContext() {
    final roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(includedPaths: [_includedPaths]);

    return ContextBuilderImpl(
      resourceProvider: resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: _sdkRoot.path,
    );
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: _sdkRoot,
    );
  }

  void test_correctFormat() {
    resourceProvider.newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example_rule:
      target: "package:example/target/*_target.dart"
      from: "package:example/from/*.dart"
      expect: ["package:example/target/expect.dart"]
''');

    final context = _buildContext();
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
    resourceProvider.newFile('/analysis_options.yaml', '''
''');

    final context = _buildContext();
    final file = context.contextRoot.optionsFile!;

    final analysisOptions = AnalysisOptions.fromYaml(file);
    final options = analysisOptions.options;

    expect(options.length, 0);
  }
}
