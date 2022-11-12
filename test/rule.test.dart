import 'dart:math';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:glob/glob.dart';
import 'package:import_lint/src/lint_options.dart';
import 'package:import_lint/src/rule.dart';
import 'package:import_lint/src/utils.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuleTest);
    defineReflectiveTests(MultiPackageRuleTest);
    defineReflectiveTests(PackageNameEmptyRuleTest);
  });
}

@reflectiveTest
class RuleTest with ResourceProviderMixin {
  RuleTest() {
    setUp();
  }

  Folder get sdkRoot => newFolder('/sdk');

  String get _includedPaths => absoluteNormalizedPath('./');

  String get _packagesPath => absoluteNormalizedPath('/.packages');

  String get _packageName => 'tests';

  DriverBasedAnalysisContext _buildContext() {
    resourceProvider.newFile(_packagesPath, '''
tests:lib/
''');

    newPubspecYamlFile('/', '''
name: $_packageName
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');

    final roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(
      includedPaths: [_includedPaths],
      packagesFile: _packagesPath,
    );

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

  void test_notAllowImport() async {
    final testFilePath = '/lib/test/1_test.dart';
    final testFileContent = '''
import '2_test.dart';
import 'package:$_packageName/test/2_test.dart';
import '3_not.dart';
''';

    resourceProvider.newFile(testFilePath, testFileContent);

    final context = _buildContext();

    final options = LintOptions(
      rules: RulesOption(
        [
          RuleOption(
            name: 'name',
            targetFilePath: Glob(
              '**/*.dart',
              recursive: true,
              caseSensitive: false,
            ),
            notAllowImports: [
              ImportRulePath(
                null,
                Glob(
                  'test/*_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
            excludeImports: [],
          ),
        ],
      ),
      common: CommonOption(directoryPath: '/'),
    );

    final errors = await getErrors(options, context, testFilePath);

    expect(errors.length, 2);
  }

  void test_excludeImport() async {
    final testFilePath = '/lib/test/1_test.dart';
    final testFileContent = '''
import '2_test.dart';
import 'package:$_packageName/test/2_test.dart';
import '3_test.dart';
''';

    resourceProvider.newFile(testFilePath, testFileContent);

    final context = _buildContext();

    final options = LintOptions(
      rules: RulesOption(
        [
          RuleOption(
            name: 'name',
            targetFilePath: Glob(
              '**/*.dart',
              recursive: true,
              caseSensitive: false,
            ),
            notAllowImports: [
              ImportRulePath(
                null,
                Glob(
                  'test/*_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
            excludeImports: [
              ImportRulePath(
                null,
                Glob(
                  'test/2_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
          ),
        ],
      ),
      common: CommonOption(directoryPath: '/'),
    );

    final errors = await getErrors(options, context, testFilePath);

    expect(errors.length, 1);
  }
}

@reflectiveTest
class MultiPackageRuleTest with ResourceProviderMixin {
  MultiPackageRuleTest() {
    setUp();
  }

  Folder get sdkRoot => newFolder('/sdk');

  String get _includedPaths => absoluteNormalizedPath('./');

  String get _packagesPath => absoluteNormalizedPath('/.packages');

  String get _packageName => 'tests';

  String get _packageDir => 'tests';

  String get _anotherPackageName => 'another';

  String get _anotherPackageDir => 'another';

  DriverBasedAnalysisContext _buildContext() {
    resourceProvider.newFile(_packagesPath, '''
$_packageName:$_packageDir/lib/
$_anotherPackageName:$_anotherPackageDir/lib/
''');

    newPubspecYamlFile('/', '''
name: $_packageName
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');

    final roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(
      includedPaths: [_includedPaths],
      packagesFile: _packagesPath,
    );

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

  void test_notAllowImport() async {
    final testFilePath = '/lib/$_packageDir/test/1_test.dart';
    final testFileContent = '''
import 'package:$_anotherPackageName/test/1_test.dart';
''';

    resourceProvider.newFile(testFilePath, testFileContent);

    final context = _buildContext();

    final options = LintOptions(
      rules: RulesOption(
        [
          RuleOption(
            name: 'name',
            targetFilePath: Glob(
              '**/*.dart',
              recursive: true,
              caseSensitive: false,
            ),
            notAllowImports: [
              ImportRulePath(
                _anotherPackageName,
                Glob(
                  'test/*_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
            excludeImports: [],
          ),
        ],
      ),
      common: CommonOption(directoryPath: '/'),
    );

    final errors = await getErrors(options, context, testFilePath);

    expect(errors.length, 1);
  }

  void test_excludeImport() async {
    final testFilePath = '/lib/$_packageDir/test/1_test.dart';
    final testFileContent = '''
import 'package:$_anotherPackageName/test/1_test.dart';
''';

    resourceProvider.newFile(testFilePath, testFileContent);

    final context = _buildContext();

    final options = LintOptions(
      rules: RulesOption(
        [
          RuleOption(
            name: 'name',
            targetFilePath: Glob(
              '**/*.dart',
              recursive: true,
              caseSensitive: false,
            ),
            notAllowImports: [
              ImportRulePath(
                _anotherPackageName,
                Glob(
                  'test/*_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
            excludeImports: [
              ImportRulePath(
                _anotherPackageName,
                Glob(
                  'test/1_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
          ),
        ],
      ),
      common: CommonOption(directoryPath: '/'),
    );

    final errors = await getErrors(options, context, testFilePath);

    expect(errors.length, 0);
  }
}

@reflectiveTest
class PackageNameEmptyRuleTest with ResourceProviderMixin {
  PackageNameEmptyRuleTest() {
    setUp();
  }

  Folder get sdkRoot => newFolder('/sdk');

  String get _includedPaths => absoluteNormalizedPath('./');

  String get _packagesPath => absoluteNormalizedPath('/.packages');

  String get _packageName => 'tests';

  DriverBasedAnalysisContext _buildContext() {
    resourceProvider.newFile(_packagesPath, '''
tests:lib/
''');

    newPubspecYamlFile('/', '''
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');

    final roots = ContextLocatorImpl(
      resourceProvider: resourceProvider,
    ).locateRoots(
      includedPaths: [_includedPaths],
      packagesFile: _packagesPath,
    );

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

  void test_notAllowImport() async {
    final testFilePath = '/lib/test/1_test.dart';
    final testFileContent = '''
import '2_test.dart';
import 'package:$_packageName/test/2_test.dart';
import '3_not.dart';
''';

    resourceProvider.newFile(testFilePath, testFileContent);

    final context = _buildContext();

    final options = LintOptions(
      rules: RulesOption(
        [
          RuleOption(
            name: 'name',
            targetFilePath: Glob(
              '**/*.dart',
              recursive: true,
              caseSensitive: false,
            ),
            notAllowImports: [
              ImportRulePath(
                null,
                Glob(
                  'test/*_test.dart',
                  recursive: true,
                  caseSensitive: false,
                ),
              ),
            ],
            excludeImports: [],
          ),
        ],
      ),
      common: CommonOption(directoryPath: '/'),
    );

    await context.applyPendingFileChanges();
    getErrors(options, context, testFilePath).then((value) {
      print(value);
    });

    final errors = await getErrors(options, context, testFilePath);
    print(['errors', errors]);
    //expect(errors.length, 0);
  }
}

String randomString(int len) {
  final r = Random();
  final generated =
      String.fromCharCodes(List.generate(len, (index) => r.nextInt(33) + 89));
  return generated;
}
