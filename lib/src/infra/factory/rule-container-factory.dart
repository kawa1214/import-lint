import 'package:import_lint/src/infra/factory/rule-factory.dart';

import '../../domain/rule_container.dart';

class RuleContainerFactory {
  RuleContainerFactory(this._reader) {
    _rawRules = _reader.read();
  }

  late final List<RawRule> _rawRules;
  final RawRulesReader _reader;

  List<RuleContainer> create() {
    final List<RuleContainer> containers = [];
    for (final rawRule in _rawRules) {
      final ruleFactory =
          RuleFactory(ruleMap: rawRule.ruleMap, ruleName: rawRule.name);
      containers.add(RuleContainer(
        name: rawRule.name,
        constraintRules: ruleFactory.createConstraints(),
        elegibleRules: ruleFactory.createElegibles(),
      ));
    }
    return containers;
  }
}

class RawRule {
  const RawRule({
    required this.name,
    required this.ruleMap,
  });

  final String name;
  final Map<String, dynamic> ruleMap;
}

abstract class RawRulesReader {
  List<RawRule> read();
}
