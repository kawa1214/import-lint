import 'package:glob/glob.dart';

import '../../domain/rules/import-allowed.dart';
import '../../domain/rules/rule.dart';
import '../../domain/rules/source-file-included.dart';

class RuleFactory {
  RuleFactory({
    required this.ruleMap,
    required this.ruleName,
  });

  Map<String, dynamic> ruleMap;
  String ruleName;

  List<ConstraintRule> createConstraints() {
    return [
      _createImportAllowedRule(),
    ];
  }

  List<ElegibleRule> createElegibles() {
    return [
      _createSourceFileIncludedRule(),
    ];
  }

  SourceFileIncluded _createSourceFileIncludedRule() {
    final targetFilePathValue = ruleMap['target_file_path'] as String?;
    if (targetFilePathValue == null) {
      throw FormatException('$ruleName: target_file_path is required.');
    }

    final includedFilesPattern =
        Glob(targetFilePathValue, recursive: true, caseSensitive: false);
    final excludedFilesPattern = _parseArray('ignore_files');
    return SourceFileIncluded(
      includedFilesPattern: includedFilesPattern,
      excludedFilesPattern: excludedFilesPattern,
    );
  }

  ImportAllowed _createImportAllowedRule() {
    return ImportAllowed(
        forbiddenImports: _parseArray('not_allow_imports'),
        excludedImports: _parseArray('exclude_imports'));
  }

  List<Glob> _parseArray(String key) => List.from(ruleMap[key] ?? [])
      .map((e) => Glob(e, recursive: true, caseSensitive: false))
      .toList();
}
