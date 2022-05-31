import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart' as yaml;

class ImportLintOptions {
  const ImportLintOptions({required this.rules, required this.common});

  factory ImportLintOptions.init({
    required String directoryPath,
    required String optionsFilePath,
  }) {
    final common = CommonOption.fromYaml(directoryPath);
    final rules = RulesOption.fromOptionsFile(optionsFilePath, common);
    return ImportLintOptions(
      rules: rules,
      common: common,
    );
  }

  final RulesOption rules;
  final CommonOption common;
}

class CommonOption {
  const CommonOption({
    required this.directoryPath,
  });

  factory CommonOption.fromYaml(String directoryPath) {
    return CommonOption(
      directoryPath: directoryPath,
    );
  }

  final String directoryPath;
}

class RulesOption {
  const RulesOption(this.value);
  factory RulesOption.fromOptionsFile(String path, CommonOption commonOption) {
    late String readValue;
    try {
      readValue = io.File(path).readAsStringSync();
    } on Exception catch (e) {
      throw Exception(
        'Not found analysis_options.yaml file '
        'at the root of your project.'
        '\n $e',
      );
    }
    final loadedYaml = yaml.loadYaml(readValue);
    final encoded = convert.jsonEncode(loadedYaml['import_lint']['rules']);
    final rulesMap = convert.jsonDecode(encoded) as Map<String, dynamic>;

    final ruleNames = rulesMap.keys.toList();

    final result = <RuleOption>[];

    for (final name in ruleNames) {
      final ruleMap = rulesMap[name];
      final rule = RuleOption.ofMap(
        ruleMap: ruleMap,
        name: name,
        commonOption: commonOption,
      );

      result.add(rule);
    }
    return RulesOption(result);
  }
  final List<RuleOption> value;
}

class RuleOption {
  const RuleOption({
    required this.name,
    required this.targetFilePath,
    required this.notAllowImports,
    required this.excludeImports,
  });

  factory RuleOption.ofMap({
    required Map<String, dynamic> ruleMap,
    required String name,
    required CommonOption commonOption,
  }) {
    final targetFilePath = Glob(ruleMap['target_file_path'],
        recursive: true, caseSensitive: false);

    final notAllowImports = (ruleMap['not_allow_imports'] as List<dynamic>)
        .map((e) => ImportRulePath.from(e.toString(), commonOption))
        .toList();
    final excludeImports = (ruleMap['exclude_imports'] as List<dynamic>)
        .map((e) => ImportRulePath.from(e.toString(), commonOption))
        .toList();

    return RuleOption(
      name: name,
      targetFilePath: targetFilePath,
      notAllowImports: notAllowImports,
      excludeImports: excludeImports,
    );
  }

  final String name;
  final Glob targetFilePath;
  final List<ImportRulePath> notAllowImports;
  final List<ImportRulePath> excludeImports;
}

class ImportRulePath {
  const ImportRulePath(this.package, this.path);

  factory ImportRulePath.from(String value, CommonOption commonOption) {
    final package = RegExp('(?<=package:).*?(?=\/)').stringMatch(value);
    if (package != null) {
      final importPath = value.replaceFirst('package:$package/', '');
      final path = Glob(importPath, recursive: true, caseSensitive: false);

      return ImportRulePath(package, path);
    }

    final path = Glob(value, recursive: true, caseSensitive: false);
    return ImportRulePath(null, path);
  }

  final String? package;
  final Glob path;
}
