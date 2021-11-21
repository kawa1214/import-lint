import 'dart:convert' as convert;

import 'dart:io' as io;
import 'package:yaml/yaml.dart' as yaml;

class Rules {
  const Rules(this.value);
  final List<Rule> value;
  factory Rules.fromParsedYaml(String? path) {
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
      final rule = rulesMap[name];

      final searchFilePathRegExp = RegExp(rule['search_file_path_reg_exp']);

      final notAllowImportRegExps =
          (rule['not_allow_import_reg_exps'] as List<dynamic>)
              .map((e) => RegExp(e.toString()))
              .toList();

      final excludeImportRegExps =
          (rule['exclude_import_reg_exps'] as List<dynamic>)
              .map((e) => RegExp(e.toString()))
              .toList();

      result.add(
        Rule(
          name: name,
          searchFilePathRegExp: searchFilePathRegExp,
          notAllowImportRegExps: notAllowImportRegExps,
          excludeImportRegExps: excludeImportRegExps,
        ),
      );
    }
    return Rules(result);
  }
}

class Rule {
  const Rule({
    required this.name,
    required this.searchFilePathRegExp,
    required this.notAllowImportRegExps,
    required this.excludeImportRegExps,
  });

  final String name;
  final RegExp searchFilePathRegExp;
  final List<RegExp> notAllowImportRegExps;
  final List<RegExp> excludeImportRegExps;
}
