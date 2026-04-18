import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:path/path.dart' as p;

/// A mixin that provides a [MemoryResourceProvider] and some helper methods.
///
/// Please make sure to call the [setUp] function.
mixin BaseResourceProviderMixin {
  MemoryResourceProvider _resourceProvider = MemoryResourceProvider();

  void _createSdkFolder() {
    newFolder('/sdk');
  }

  String get packageName => 'example';

  String get anotherPackageName => 'another';
  String get _anotherPackageDir => 'another';

  void _createPubspecYamlFile() {
    newFile('/pubspec.yaml', '''
name: $packageName
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
  }

  /// Create a package_config.json so the analyzer recognises this as a
  /// [PackageConfigWorkspace] (required by analyzer ≥ 12 which no longer
  /// reads legacy `.packages` files).
  void _createPackageConfigFile() {
    newFile('/.dart_tool/package_config.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "$packageName",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    },
    {
      "name": "$anotherPackageName",
      "rootUri": "../$_anotherPackageDir",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ],
  "generated": "2024-01-01T00:00:00.000000Z",
  "generator": "pub",
  "generatorVersion": "3.0.0"
}
''');
  }

  Folder get _sdkRoot => getFolder('/sdk');

  void setUp() {
    _createSdkFolder();
    _createPubspecYamlFile();
    _createPackageConfigFile();
    createMockSdk(resourceProvider: _resourceProvider, root: _sdkRoot);
  }

  DriverBasedAnalysisContext buildContext() {
    final roots = locateContextRoots(
      includedPaths: [_convertPath('/lib')],
      resourceProvider: _resourceProvider,
    );

    return ContextBuilderImpl(
      resourceProvider: _resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: _sdkRoot.path,
      withFineDependencies: false,
    );
  }

  /// Converts a posix-style [path] to the resource provider's path style.
  ///
  /// Inlined here instead of calling the deprecated `convertPath` on
  /// `MemoryResourceProvider` so we don't need the analyzer_testing package.
  String _convertPath(String path) {
    final ctx = _resourceProvider.pathContext;
    if (ctx.style != p.windows.style) return path;
    var result = path;
    if (result.startsWith(p.posix.separator)) {
      result = r'C:' + result;
    }
    return result.replaceAll(p.posix.separator, p.windows.separator);
  }

  Folder newFolder(String path) {
    final convertedPath = _convertPath(path);
    return _resourceProvider.newFolder(convertedPath);
  }

  Folder getFolder(String path) {
    final convertedPath = _convertPath(path);
    return _resourceProvider.getFolder(convertedPath);
  }

  File newFile(String path, String content) {
    final convertedPath = _convertPath(path);
    return _resourceProvider.newFile(convertedPath, content);
  }

  File getFile(String path) {
    final convertedPath = _convertPath(path);
    return _resourceProvider.getFile(convertedPath);
  }
}
