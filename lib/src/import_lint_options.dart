import 'dart:io' as io;

import 'package:import_lint/src/import_lint_options/rule.dart';
import 'package:yaml/yaml.dart' as yaml;

class ImportLintOptions {
  const ImportLintOptions({
    required this.rules,
    required this.directoryPath,
    required this.packageName,
  });

  factory ImportLintOptions.init({required String directoryPath}) {
    final rules = Rules.fromOptionsFile(_optionsFilePath(directoryPath));
    return ImportLintOptions(
      rules: rules,
      directoryPath: directoryPath,
      packageName: _packageName(directoryPath),
    );
  }

  final Rules rules;
  final String directoryPath;
  final String packageName;

  static const _pubspecFileName = 'pubspec.yaml';

  static String _packageName(String directoryPath) {
    final pubspecFile = io.File('$directoryPath/$_pubspecFileName');
    late String value;
    try {
      value = pubspecFile.readAsStringSync();
    } on Exception catch (e) {
      throw Exception(
        'Not found pubspec.yaml file'
        'at the root of your project.'
        '\n$e',
      );
    }
    final loadYaml = yaml.loadYaml(value);
    return loadYaml['name'];
  }

  static const _optionsFileName = 'analysis_options.yaml';

  static String _optionsFilePath(String directoryPath) =>
      '${directoryPath}/$_optionsFileName';
}
