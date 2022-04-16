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
    final rules = RulesOption.fromOptionsFile(optionsFilePath);
    final common = CommonOption.fromYaml(directoryPath);
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
    required this.packageName,
  });

  factory CommonOption.fromYaml(String directoryPath) {
    return CommonOption(
      directoryPath: directoryPath,
      packageName: _packageName(directoryPath),
    );
  }

  final String directoryPath;
  final String packageName;

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

  static const _pubspecFileName = 'pubspec.yaml';
}

class RulesOption {
  const RulesOption(this.value);
  factory RulesOption.fromOptionsFile(String path) {
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

    final result = <Rule>[];
    for (final name in ruleNames) {
      final ruleMap = rulesMap[name];
      final rule = Rule.ofMap(ruleMap: ruleMap, name: name);

      result.add(rule);
    }
    return RulesOption(result);
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
    final targetFilePath = Glob(_globCanonicalize(ruleMap['target_file_path']));
    print(['rule target', _globCanonicalize(ruleMap['target_file_path'])]);

    final notAllowImports = (ruleMap['not_allow_imports'] as List<dynamic>)
        .map((e) => Glob(_globCanonicalize(e.toString())))
        .toList();
    final excludeImports = (ruleMap['exclude_imports'] as List<dynamic>)
        .map((e) => Glob(_globCanonicalize(e.toString())))
        .toList();

    return Rule(
      name: name,
      targetFilePath: targetFilePath,
      notAllowImports: notAllowImports,
      excludeImports: excludeImports,
    );
  }

  static String _globCanonicalize(String value) {
    if (io.Platform.isWindows) {
      return value.replaceAll('/', r'\');
    }
    return value.replaceAll(r'\', '/');
  }

  final String name;
  final Glob targetFilePath;
  final List<Glob> notAllowImports;
  final List<Glob> excludeImports;
}
