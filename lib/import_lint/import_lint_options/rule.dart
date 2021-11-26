import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart' as yaml;

class Rules {
  const Rules(this.value);
  factory Rules.fromOptionsFile(String path) {
    late String readValue;
    try {
      readValue = io.File(path).readAsStringSync();
    } on Exception catch (e) {
      throw Exception(
        'Not found import_analysis_options.yaml file'
        'at the root of your project.'
        '\n $e',
      );
    }
    final loadedYaml = yaml.loadYaml(readValue);
    final encoded = convert.jsonEncode(loadedYaml['import_lint']['rules']);
    final rulesMap = convert.jsonDecode(encoded) as Map<String, dynamic>;

    final ruleNames = rulesMap.keys.toList();

    final result = <Rule>[];
    for (final name in ruleNames) {
      final ruleMap = rulesMap[name];
      final rule = Rule.ofMap(ruleMap: ruleMap, name: name);

      result.add(rule);
    }
    return Rules(result);
  }
  final List<Rule> value;
}

class Rule {
  const Rule({
    required this.name,
    required this.targetFilePath,
    required this.notAllowImports,
    required this.excludeImports,
  });

  factory Rule.ofMap({
    required Map<String, dynamic> ruleMap,
    required String name,
  }) {
    final targetFilePath = Glob(ruleMap['target_file_path']);

    final notAllowImports = (ruleMap['not_allow_imports'] as List<dynamic>)
        .map((e) => Glob(e.toString()))
        .toList();
    final excludeImports = (ruleMap['exclude_imports'] as List<dynamic>)
        .map((e) => Glob(e.toString()))
        .toList();

    return Rule(
      name: name,
      targetFilePath: targetFilePath,
      notAllowImports: notAllowImports,
      excludeImports: excludeImports,
    );
  }
  final String name;
  final Glob targetFilePath;
  final List<Glob> notAllowImports;
  final List<Glob> excludeImports;
}