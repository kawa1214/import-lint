import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:glob/glob.dart';
import 'package:import_lint/src/lint_options.dart';
import 'package:import_lint/src/utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group('RuleTest', () {
    test('shoud two unauthorized imports in same package', () {
      RuleTest().notAllowImportTest();
    });
    test('shoud zero unauthorized imports in same package', () {
      RuleTest().excludeImportTest();
    });
    test('shoud one unauthorized imports in another package', () {
      MultiPackageRuleTest().notAllowImportTest();
    });
    test('shoud zero unauthorized imports in another package', () {
      MultiPackageRuleTest().excludeImportTest();
    });
    test('shoud zero unauthorized imports when package name empty', () {
      PackageNameEmptyRuleTest().notAllowImportTest();
    });
  });
}

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

  void notAllowImportTest() async {
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

  void excludeImportTest() async {
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

  void notAllowImportTest() async {
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

  void excludeImportTest() async {
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

  void notAllowImportTest() async {
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

    expect(errors.length, 0);
  }
}
