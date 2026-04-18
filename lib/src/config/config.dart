import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

import 'rule.dart';

/// Represents the configuration for the import lint tool.
class Config {
  /// Creates a config explicitly. Prefer [Config.fromAnalysisOptions]
  /// for the common case of reading from `analysis_options.yaml`.
  const Config({required this.severity, required this.rules});

  /// Builds a [Config] from the `import_lint:` section of a parsed
  /// [analysisOptions]. Throws [ArgumentException] when the section
  /// or its required `rules:` child is missing.
  factory Config.fromAnalysisOptions(AnalysisOptions analysisOptions) {
    final root = analysisOptions.options[_rootKey];
    if (root is! Map<String, Object>) {
      throw ArgumentException('$_rootKey is required');
    }

    final severity = SeverityExtension.fromString(root[_severityKey]);

    final rulesMap = root[_rulesKey];
    if (rulesMap is! Map<String, Object>) {
      throw ArgumentException('$_rulesKey is required');
    }
    final rules = rulesMap.entries.map((e) => Rule.fromMap(e.key, e.value));

    return Config(severity: severity, rules: rules);
  }

  static const _rootKey = 'import_lint';
  static const _severityKey = 'severity';
  static const _rulesKey = 'rules';

  /// Severity reported for every violation. Defaults to
  /// [Severity.warning] when not set in `analysis_options.yaml`.
  final Severity severity;

  /// Lint rules declared under `import_lint.rules` in
  /// `analysis_options.yaml`.
  final Iterable<Rule> rules;
}
