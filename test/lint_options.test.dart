import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions.dart';
import 'package:import_lint/src/lint_options.dart';
import 'package:import_lint/src/utils.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LintOptionsTest);
  });
}

@reflectiveTest
class LintOptionsTest with ResourceProviderMixin {
  LintOptionsTest() {
    setUp();
  }

  Folder get sdkRoot => newFolder('/sdk');

  String get _includedPaths => absoluteNormalizedPath('./');

  DriverBasedAnalysisContext _buildContext() {
    final roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(includedPaths: [_includedPaths]);

    return ContextBuilderImpl(
      resourceProvider: resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: sdkRoot.path,
    );
  }

  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
  }

  void test_correctFormat() {
    resourceProvider.newFile('/analysis_options.yaml', '''
import_lint:
  rules:
    test_rule:
      target_file_path: "test/*.dart"
      not_allow_imports: ["test/*.dart"]
      exclude_imports: ["not_test/*.dart"]
    package_rule:
      target_file_path: "**/*.dart"
      not_allow_imports: ["package:import_lint/import_lint.dart"]
      exclude_imports: []
''');

    final context = _buildContext();

    final options = getOptions(context);

    expect(options.common.directoryPath, '/');
    expect(options.rules.value.length, 2);

    final testRule = options.rules.value[0];

    expect(testRule.name, 'test_rule');
    expect(
      testRule.targetFilePath.pattern,
      Glob('test/*.dart', recursive: true, caseSensitive: false).pattern,
    );
    expect(
      testRule.notAllowImports.first.package,
      null,
    );
    expect(
      testRule.notAllowImports.first.glob.pattern,
      Glob('test/*.dart', recursive: true, caseSensitive: false).pattern,
    );
    expect(
      testRule.excludeImports.first.glob.pattern,
      Glob('not_test/*.dart', recursive: true, caseSensitive: false).pattern,
    );

    final packageRule = options.rules.value[1];

    expect(packageRule.name, 'package_rule');
    expect(
      packageRule.targetFilePath.pattern,
      Glob('**/*.dart', recursive: true, caseSensitive: false).pattern,
    );
    expect(
      packageRule.notAllowImports.first.package,
      'import_lint',
    );
    expect(
      packageRule.notAllowImports.first.glob.pattern,
      Glob('import_lint.dart', recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_fileDoesNotExist() {
    final context = _buildContext();

    late FileException exception;
    try {
      getOptions(context);
    } on FileException catch (e) {
      exception = e;
    }

    expect(exception, isNotNull);
    expect(exception.runtimeType, FileException);
  }

  void test_hasNotTargetFilePathFormatException() {
    resourceProvider.newFile('/analysis_options.yaml', '''
import_lint:
  rules:
    only_target_file_path_rule:
      target_file_path: "test/*.dart"
    has_not_target_file_path_rule:
      not_allow_imports: ["package:import_lint/import_lint.dart"]
      exclude_imports: []
''');

    final context = _buildContext();

    late FormatException exception;
    try {
      getOptions(context);
    } on FormatException catch (e) {
      exception = e;
    }

    expect(
      exception.message,
      'has_not_target_file_path_rule: target_file_path is required.',
    );
  }
}
