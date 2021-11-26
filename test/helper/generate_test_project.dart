import 'dart:io';

class GenerateTestProject {
  GenerateTestProject();

  factory GenerateTestProject.ofHasNotAnalysisOptionsYaml() {
    final project = GenerateTestProject();
    project.files.addAll([GenerateFile.ofPubspecYaml()]);
    return project;
  }

  factory GenerateTestProject.ofHasNotPubspecYaml() {
    final project = GenerateTestProject();
    project.files.addAll([GenerateFile.ofAnalysisOptions()]);
    return project;
  }

  factory GenerateTestProject.ofImportLintOptions() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
    ]);
    return project;
  }

  factory GenerateTestProject.ofPackageImportDartFiles() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
      GenerateFile.ofPackageImportDartFiles(),
    ]);
    return project;
  }

  factory GenerateTestProject.ofRelativeImportDartFiles() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
      GenerateFile.ofRelativeImportDartFiles(),
    ]);
    return project;
  }

  factory GenerateTestProject.ofAbsoluteImportDartFiles() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
      GenerateFile.ofAbsoluteImportDartFiles(),
    ]);
    return project;
  }

  factory GenerateTestProject.ofLibraryPrefixIImportDartFiles() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
      GenerateFile.ofLibraryPrefixImportDartFiles(),
    ]);
    return project;
  }

  factory GenerateTestProject.ofSpacePathImportDartFiles() {
    final project = GenerateTestProject();
    project.files.addAll([
      GenerateFile.ofAnalysisOptions(),
      GenerateFile.ofPubspecYaml(),
      GenerateFile.ofSpacePathImportDartFiles(),
    ]);
    return project;
  }

  void generate() {
    reset();
    for (final file in files) {
      final path = directoryPath + file.path;
      File(path).createSync(recursive: true);
      File(path).writeAsStringSync(file.content);
    }
  }

  void reset() {
    Directory(directoryPath).deleteSync(recursive: true);
  }

  int get notAllowImportCount => files
      .map((e) => e.notAllowImportCount)
      .reduce((value, element) => value + element);

  final directoryPath =
      '${Directory.current.path}/test/helper/generated_project';
  final List<GenerateFile> files = [];
  static const packageName = 'example';
  static const rulesLength = 1;
}

class GenerateFile {
  const GenerateFile({
    required this.path,
    required this.content,
    this.notAllowImportCount = 0,
  });

  factory GenerateFile.ofPubspecYaml() {
    final content = '''
name: ${GenerateTestProject.packageName}
description: A simple command-line application.
version: 1.0.0
environment:
  sdk: ">=2.14.3 <3.0.0"

dev_dependencies:
  import_lint:
    path: ../
  lints: ^1.0.0
''';
    return GenerateFile(path: '/pubspec.yaml', content: content);
  }

  factory GenerateFile.ofAnalysisOptions() {
    final content = '''
analyzer:
  plugins:
    - import_lint

import_lint:
  rules:
    custom_rule:
      target_file_path: "/**/custom/*_target.dart"
      not_allow_imports: ["/**/custom/*_not_allow.dart", "/**/second_custom/*_not_allow.dart", "/**/space custom/*not_allow.dart"]
      exclude_imports: ["/lib/custom/exclude.dart"]
''';
    return GenerateFile(path: '/analysis_options.yaml', content: content);
  }

  factory GenerateFile.ofPackageImportDartFiles() {
    final content = '''
import 'package:${GenerateTestProject.packageName}/custom/first_target.dart';
import 'package:${GenerateTestProject.packageName}/custom/first_allow.dart';
import 'package:${GenerateTestProject.packageName}/custom/second_allow.dart';
import 'package:${GenerateTestProject.packageName}/custom/first_not_allow.dart';
import 'package:${GenerateTestProject.packageName}/custom/second_not_allow.dart';
import 'package:${GenerateTestProject.packageName}/custom/exclude.dart';
''';
    return GenerateFile(
      path: '/lib/custom/example_target.dart',
      content: content,
      notAllowImportCount: 2,
    );
  }

  factory GenerateFile.ofRelativeImportDartFiles() {
    final content = '''
import 'first_target.dart';
import 'second_target.dart';
import 'first_allow.dart';
import 'second_allow.dart';
import 'first_not_allow.dart';
import 'second_not_allow.dart';
import 'exclude.dart';
''';
    return GenerateFile(
      path: '/lib/custom/example_target.dart',
      content: content,
      notAllowImportCount: 2,
    );
  }

  factory GenerateFile.ofAbsoluteImportDartFiles() {
    final content = '''
import '../second_custom/first_target.dart';
import '../second_custom/second_target.dart';
import '../second_custom/first_allow.dart';
import '../second_custom/second_allow.dart';
import '../second_custom/first_not_allow.dart';
import '../second_custom/second_not_allow.dart';
import 'exclude.dart';
''';
    return GenerateFile(
      path: '/lib/custom/example_target.dart',
      content: content,
      notAllowImportCount: 2,
    );
  }

  factory GenerateFile.ofLibraryPrefixImportDartFiles() {
    final content = '''
import 'package:${GenerateTestProject.packageName}/custom/first_target.dart';
import 'package:${GenerateTestProject.packageName}/custom/first_target.dart' as example;
import 'package:${GenerateTestProject.packageName}/custom/first_not_allow.dart' as example;
import 'first_not_allow.dart' as example;
import '../second_custom/first_not_allow.dart' as example;
import 'exclude.dart';
''';
    return GenerateFile(
      path: '/lib/custom/example_target.dart',
      content: content,
      notAllowImportCount: 3,
    );
  }

  factory GenerateFile.ofSpacePathImportDartFiles() {
    final content = '''
import 'package:${GenerateTestProject.packageName}/space custom/first not_allow.dart' as example;
import '../space custom/first not_allow.dart' as example;
import 'exclude.dart';
''';
    return GenerateFile(
      path: '/lib/custom/example_target.dart',
      content: content,
      notAllowImportCount: 2,
    );
  }

  final String path;
  final String content;
  final int notAllowImportCount;
}
