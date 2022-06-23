import 'dart:convert' as convert;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions.dart';
import 'package:yaml/yaml.dart' as yaml;

LintOptions getOptions(DriverBasedAnalysisContext context) {
  final rootDirectoryPath = context.contextRoot.root.path;

  final options = LintOptions.init(
    directoryPath: rootDirectoryPath,
    optionsFile: context.contextRoot.optionsFile,
  );

  return options;
}

class LintOptions {
  const LintOptions({required this.rules, required this.common});

  factory LintOptions.init({
    required String directoryPath,
    required File? optionsFile,
  }) {
    final common = CommonOption.fromYaml(directoryPath);
    final rules = RulesOption.fromOptionsFile(optionsFile, common);
    return LintOptions(
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
  factory RulesOption.fromOptionsFile(
    File? optionsFile,
    CommonOption commonOption,
  ) {
    if (optionsFile == null) {
      throw _notFoundAnalytisOptionsException(null, null);
    }

    final readValue = optionsFile.readAsStringSync();

    final loadedYaml = yaml.loadYaml(readValue);
    final encoded = convert.jsonEncode(loadedYaml['import_lint']['rules']);
    final rulesMap = convert.jsonDecode(encoded) as Map<String, dynamic>? ?? {};

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

  static FileException _notFoundAnalytisOptionsException(
    Object? e,
    StackTrace? s,
  ) =>
      FileException(
        'Not found analysis_options.yaml file '
        'at the root of your project.'
        '\n $e'
        '\n $s',
      );
}

class RuleOption {
  const RuleOption({
    required this.name,
    this.ignoreFiles = const [],
    required this.targetFilePath,
    required this.notAllowImports,
    required this.excludeImports,
  });

  factory RuleOption.ofMap({
    required Map<String, dynamic> ruleMap,
    required String name,
    required CommonOption commonOption,
  }) {
    final targetFilePathValue = ruleMap['target_file_path'] as String?;
    if (targetFilePathValue == null) {
      throw FormatException('$name: target_file_path is required.');
    }

    final targetFilePath =
        Glob(targetFilePathValue, recursive: true, caseSensitive: false);

    final notAllowImports =
        _importRulesFromRuleMap(ruleMap, 'not_allow_imports', commonOption);
    final excludeImports =
        _importRulesFromRuleMap(ruleMap, 'exclude_imports', commonOption);
    final ingoreFiles =
        _importRulesFromRuleMap(ruleMap, 'ignore_files', commonOption);

    return RuleOption(
      name: name,
      ignoreFiles: ingoreFiles,
      targetFilePath: targetFilePath,
      notAllowImports: notAllowImports,
      excludeImports: excludeImports,
    );
  }

  static List<ImportRulePath> _importRulesFromRuleMap(
          Map<String, dynamic> ruleMap, String ruleKey, CommonOption option) =>
      _createImportRules(_parseArray(ruleMap[ruleKey]), option);

  static List<ImportRulePath> _createImportRules(
          List<String> rules, CommonOption option) =>
      rules.map((e) => ImportRulePath.from(e, option)).toList();

  static List<String> _parseArray(dynamic ruleArray) =>
      List.from(ruleArray ?? []);

  final String name;
  final Glob targetFilePath;
  final List<ImportRulePath> notAllowImports;
  final List<ImportRulePath> excludeImports;
  final List<ImportRulePath> ignoreFiles;
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

  String fixedPackage(String workspacePackage) =>
      package == null ? workspacePackage : package!;
}
