import 'package:import_lint/src/config/rule_path.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// The Rule class defines a lint rule.
///
/// - [target] Define the file paths of the targets to be restricted
/// - [from] Define the paths that are not allowed to be used in imports
/// - [expect] Define the exception paths for the 'from' rule
class Rule {
  const Rule({
    required this.name,
    required this.target,
    required this.from,
    required this.expect,
  });

  factory Rule.fromMap(Object? name, Object? value) {
    if (name is! String) {
      throw ArgumentException(
        'name must be a String',
      );
    }

    if (name.length == 0) {
      throw ArgumentException(
        'name must not be empty',
      );
    }

    if (value is! Map<String, Object>) {
      throw ArgumentException(
        'must be a Map<String, Object>',
      );
    }

    final target = RulePath.fromString(value['target']);
    final from = RulePath.fromString(value['from']);

    final expect = value['expect'];
    if (expect is! List<String>) {
      throw ArgumentException(
        'expect must be a List<String>',
      );
    }
    final expectRulePaths = <RulePath>[];
    for (final expectRulePath in expect) {
      final rulePath = RulePath.fromString(expectRulePath);
      expectRulePaths.add(rulePath);
    }

    return Rule(
      name: name,
      target: target,
      from: from,
      expect: expectRulePaths,
    );
  }

  final String name;
  final RulePath target;
  final RulePath from;
  final List<RulePath> expect;
}
