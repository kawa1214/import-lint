import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/context_locator.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';

/// A mixin that provides a [MemoryResourceProvider] and some helper methods.
///
/// Please make sure to call the [setUp] function.
mixin BaseResourceProviderMixin {
  MemoryResourceProvider _resourceProvider = MemoryResourceProvider();

  void _createSdkFolder() {
    newFolder('/sdk');
  }

  String get packageName => 'example';

  void _createPubspecYamlFile() {
    newFile('/pubspec.yaml', '''
name: $packageName
version: 1.0.0
environment:
  sdk: '>=2.12.0 <3.0.0'
''');
  }

  Folder get _sdkRoot => getFolder('/sdk');

  String get _includedPaths => _absoluteNormalizedPath('./');

  void setUp() {
    _createSdkFolder();
    _createPubspecYamlFile();
    createMockSdk(
      resourceProvider: _resourceProvider,
      root: _sdkRoot,
    );
  }

  DriverBasedAnalysisContext buildContext() {
    final roots = ContextLocatorImpl(
      resourceProvider: _resourceProvider,
    ).locateRoots(includedPaths: [_includedPaths]);

    return ContextBuilderImpl(
      resourceProvider: _resourceProvider,
    ).createContext(
      contextRoot: roots.single,
      sdkPath: _sdkRoot.path,
    );
  }

  String _convertPath(String path) => _resourceProvider.convertPath(path);

  String _absoluteNormalizedPath(String path) {
    final pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    return pathContext.normalize(
      pathContext.absolute(path),
    );
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
