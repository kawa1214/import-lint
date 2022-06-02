import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

mixin ResourceProviderMixin {
  MemoryResourceProvider resourceProvider = MemoryResourceProvider();

  String convertPath(String path) => resourceProvider.convertPath(path);

  void deleteAnalysisOptionsYamlFile(String directoryPath) {
    final path = join(directoryPath, file_paths.analysisOptionsYaml);
    deleteFile(path);
  }

  void deleteFile(String path) {
    final String convertedPath = convertPath(path);
    resourceProvider.deleteFile(convertedPath);
  }

  void deleteFolder(String path) {
    final String convertedPath = convertPath(path);
    resourceProvider.deleteFolder(convertedPath);
  }

  void deletePackageConfigJsonFile(String directoryPath) {
    final path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    deleteFile(path);
  }

  File getFile(String path) {
    final String convertedPath = convertPath(path);
    return resourceProvider.getFile(convertedPath);
  }

  Folder getFolder(String path) {
    final String convertedPath = convertPath(path);
    return resourceProvider.getFolder(convertedPath);
  }

  String join(String part1,
          [String? part2,
          String? part3,
          String? part4,
          String? part5,
          String? part6,
          String? part7,
          String? part8]) =>
      resourceProvider.pathContext
          .join(part1, part2, part3, part4, part5, part6, part7, part8);

  void modifyFile(String path, String content) {
    final String convertedPath = convertPath(path);
    resourceProvider.modifyFile(convertedPath, content);
  }

  File newAnalysisOptionsYamlFile(String directoryPath, String content) {
    final String path = join(directoryPath, file_paths.analysisOptionsYaml);
    return newFile(path, content);
  }

  @Deprecated('Use newAnalysisOptionsYamlFile() instead')
  File newAnalysisOptionsYamlFile2(String directoryPath, String content) {
    return newAnalysisOptionsYamlFile(directoryPath, content);
  }

  File newBazelBuildFile(String directoryPath, String content) {
    final String path = join(directoryPath, file_paths.bazelBuild);
    return newFile(path, content);
  }

  File newFile(String path, String content) {
    final String convertedPath = convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }

  @Deprecated('Use newFile() instead')
  File newFile2(String path, String content) {
    final String convertedPath = convertPath(path);
    return resourceProvider.newFile(convertedPath, content);
  }

  Folder newFolder(String path) {
    final String convertedPath = convertPath(path);
    return resourceProvider.newFolder(convertedPath);
  }

  File newPackageConfigJsonFile(String directoryPath, String content) {
    final String path = join(
      directoryPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    return newFile(path, content);
  }

  File newPubspecYamlFile(String directoryPath, String content) {
    final String path = join(directoryPath, file_paths.pubspecYaml);
    return newFile(path, content);
  }

  Uri toUri(String path) {
    path = convertPath(path);
    return resourceProvider.pathContext.toUri(path);
  }

  String toUriStr(String path) {
    return toUri(path).toString();
  }
}

void createMockSdk({
  required MemoryResourceProvider resourceProvider,
  required Folder root,
}) {
  final lib = root.getChildAssumingFolder('lib');
  final libInternal = lib.getChildAssumingFolder('_internal');

  final currentVersion = ExperimentStatus.currentVersion;
  final currentVersionStr = '${currentVersion.major}.${currentVersion.minor}.0';
  root.getChildAssumingFile('version').writeAsStringSync(currentVersionStr);

  final librariesBuffer = StringBuffer();
  librariesBuffer.writeln(
    'const Map<String, LibraryInfo> libraries = const {',
  );

  // TODO: 削除する
  for (final library in [..._LIBRARIES]) {
    for (final unit in library.units) {
      final file = lib.getChildAssumingFile(unit.path);
      file.writeAsStringSync(unit.content);
    }
    librariesBuffer.writeln(
      '  "${library.name}": const LibraryInfo("${library.path}", '
      'categories: "${library.categories}"),',
    );
  }

  librariesBuffer.writeln('};');
  libInternal
      .getChildAssumingFile('sdk_library_metadata/lib/libraries.dart')
      .writeAsStringSync('$librariesBuffer');

  libInternal
      .getChildAssumingFile('allowed_experiments.json')
      .writeAsStringSync(
        json.encode({
          'version': 1,
          'experimentSets': {
            'sdkExperiments': <String>[],
            'nullSafety': ['non-nullable']
          },
          'sdk': {
            'default': {'experimentSet': 'sdkExperiments'},
          },
          'packages': <String, Object>{},
        }),
      );
}

class MockSdkLibrary implements SdkLibrary {
  MockSdkLibrary(this.name, this.units, {this.categories = 'Shared'});
  final String name;
  final String categories;
  final List<MockSdkLibraryUnit> units;

  @override
  String get category => throw UnimplementedError();

  @override
  bool get isDart2JsLibrary => throw UnimplementedError();

  @override
  bool get isDocumented => throw UnimplementedError();

  @override
  bool get isImplementation => throw UnimplementedError();

  @override
  bool get isInternal => shortName.startsWith('dart:_');

  @override
  bool get isShared => throw UnimplementedError();

  @override
  bool get isVmLibrary => throw UnimplementedError();

  @override
  String get path => units[0].path;

  @override
  String get shortName => 'dart:$name';
}

class MockSdkLibraryUnit {
  MockSdkLibraryUnit(this.path, this.content);
  final String path;
  final String content;
}

final List<MockSdkLibrary> _LIBRARIES = [];
