import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:glob/glob.dart';
import 'package:import_lint/import_lint.dart';
import 'package:import_lint/src/exceptions.dart';
import 'package:import_lint/src/utils.dart';
import 'package:meta/meta.dart' show mustCallSuper;
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'helper/analyzer_helper.dart';

main() {
  group('LintOptionsTest', () {
    test('should succeed when has correct format analysis_options.yaml', () {
      LintOptionsTest().correctFormatTest();
    });
    test('shoud throw file exception when has not analysis_options.yaml', () {
      LintOptionsTest().fileDoesNotExistText();
    });
    test('shoud throw format exception when has not target file path', () {
      LintOptionsTest().hasNotTargetFilePathFormatExceptionTest();
    });
  });
}

class LintOptionsTest with ResourceProviderMixin {
  LintOptionsTest() {
    setUp();
  }

  Folder get sdkRoot => newFolder('/sdk');

  @mustCallSuper
  void setUp() {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
  }

  void correctFormatTest() {
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

    final collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [absoluteNormalizedPath('./')],
      sdkPath: sdkRoot.path,
    );

    final options = getOptions(collection);

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
      testRule.notAllowImports.first.path.pattern,
      Glob('test/*.dart', recursive: true, caseSensitive: false).pattern,
    );
    expect(
      testRule.excludeImports.first.path.pattern,
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
      packageRule.notAllowImports.first.path.pattern,
      Glob('import_lint.dart', recursive: true, caseSensitive: false).pattern,
    );
  }

  void fileDoesNotExistText() {
    final collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [absoluteNormalizedPath('./')],
      sdkPath: sdkRoot.path,
    );

    late FileException exception;
    try {
      getOptions(collection);
    } on FileException catch (e) {
      exception = e;
    }

    expect(exception, isNotNull);
    expect(exception.runtimeType, FileException);
  }

  void hasNotTargetFilePathFormatExceptionTest() {
    resourceProvider.newFile('/analysis_options.yaml', '''
import_lint:
  rules:
    only_target_file_path_rule:
      target_file_path: "test/*.dart"
    has_not_target_file_path_rule:
      not_allow_imports: ["package:import_lint/import_lint.dart"]
      exclude_imports: []
''');

    final collection = AnalysisContextCollectionImpl(
      resourceProvider: resourceProvider,
      includedPaths: [absoluteNormalizedPath('./')],
      sdkPath: sdkRoot.path,
    );

    late FormatException exception;
    try {
      getOptions(collection);
    } on FormatException catch (e) {
      exception = e;
    }

    expect(
      exception.message,
      'has_not_target_file_path_rule: target_file_path is required.',
    );
  }
}
