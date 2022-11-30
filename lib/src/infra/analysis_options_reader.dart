// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert' as convert;

import 'package:analyzer/file_system/file_system.dart';
import 'package:import_lint/src/infra/factory/rule-container-factory.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'exceptions.dart';

class AnalysisOptionsReader implements RawRulesReader {
  AnalysisOptionsReader({
    this.optionsFile,
  });

  File? optionsFile;

  @override
  List<RawRule> read() {
    if (optionsFile == null) {
      throw _notFoundAnalytisOptionsException();
    }

    final readValue = optionsFile!.readAsStringSync();

    final loadedYaml = yaml.loadYaml(readValue);
    final encoded = convert.jsonEncode(loadedYaml['import_lint']['rules']);
    final rulesMap = convert.jsonDecode(encoded) as Map<String, dynamic>? ?? {};

    final ruleNames = rulesMap.keys.toList();

    final result = <RawRule>[];

    for (final name in ruleNames) {
      final ruleMap = rulesMap[name];
      final rawRule = RawRule(name: name, ruleMap: ruleMap);

      result.add(rawRule);
    }
    return result;
  }

  FileException _notFoundAnalytisOptionsException() =>
      FileException('Not found analysis_options.yaml file '
          'at the root of your project.');
}
