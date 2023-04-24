import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

import 'rule.dart';

class Config {
  const Config({
    required this.severity,
    required this.rules,
  });

  factory Config.fromAnalysisOptions(AnalysisOptions analysisOptions) {
    final root = analysisOptions.options[_rootKey];
    if (!(root is Map<String, Object>)) {
      throw ArgumentException(
        '$_rootKey is required',
      );
    }

    final severity = SeverityExtension.fromString(root[_severityKey]);

    final rulesMap = root[_rulesKey];
    if (!(rulesMap is Map<String, Object>)) {
      throw ArgumentException(
        '$_rulesKey is required',
      );
    }
    final rules =
        rulesMap.entries.map((e) => Rule.fromMap(e.key, e.value)).toList();

    return Config(
      severity: severity,
      rules: rules,
    );
  }

  static const _rootKey = 'import_lint';
  static const _severityKey = 'severity';
  static const _rulesKey = 'rules';

  final Severity severity;
  final List<Rule> rules;
}
