import 'package:import_lint/src/domain/import.dart';

import 'rules/rule.dart';

class RuleContainer {
  RuleContainer({
    required this.name,
    required this.constraintRules,
    required this.elegibleRules,
  });

  final String name;
  final List<ConstraintRule> constraintRules;
  final List<ElegibleRule> elegibleRules;

  bool isAnyRuleViolatedBy(Import import) {
    if (_shouldSkip(import)) {
      return false;
    }
    final result =
        this.constraintRules.any((rule) => rule.isViolatedBy(import));
    return result;
  }

  bool _shouldSkip(Import import) {
    return this.elegibleRules.every((rule) => !rule.isImportElegible(import));
  }
}
