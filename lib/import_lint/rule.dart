import 'dart:convert' as convert;

import 'dart:io' as io;
import 'package:yaml/yaml.dart' as yaml;
import 'package:glob/glob.dart';

class Rules {
  const Rules(this.value);
  final List<Rule> value;
  factory Rules.fromOptionsFile(String? path) {
    if (path == null) {
      throw Exception(
        'Not Found: import_analysis_options.yaml file at the root of your project.',
      );
    }

    final file = io.File(path);
    final value = file.readAsStringSync();
    final loadedYaml = yaml.loadYaml(value);
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
}

class Rule {
  const Rule({
    required this.name,
    required this.searchFilePath,
    required this.notAllowImports,
    required this.excludeImports,
  });

  final String name;
  final Glob searchFilePath;
  final List<Glob> notAllowImports;
  final List<Glob> excludeImports;

  factory Rule.ofMap({
    required Map<String, dynamic> ruleMap,
    required String name,
  }) {
    final searchFilePath = Glob(ruleMap['search_file_path']);

    final notAllowImports = (ruleMap['not_allow_imports'] as List<dynamic>)
        .map((e) => Glob(e.toString()))
        .toList();
    final excludeImports = (ruleMap['exclude_imports'] as List<dynamic>)
        .map((e) => Glob(e.toString()))
        .toList();

    return Rule(
      name: name,
      searchFilePath: searchFilePath,
      notAllowImports: notAllowImports,
      excludeImports: excludeImports,
    );
  }
}
