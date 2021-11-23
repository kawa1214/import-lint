import 'package:yaml/yaml.dart' as yaml;

import 'dart:io' as io;

const fileName = 'pubspec.yaml';

String packageNameFromPath(String path) {
  final pubspecFile = io.File('$path/$fileName');
  final value = pubspecFile.readAsStringSync();
  final loadYaml = yaml.loadYaml(value);

  return loadYaml['name'];
}
