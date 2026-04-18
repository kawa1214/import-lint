import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// Defines a single lint rule with its associated constraints in the import lint configuration.
class Rule {
  /// Builds a rule explicitly. Most callers should use
  /// [Rule.fromMap] instead, which validates input from YAML.
  const Rule(this.name, this.constraints);

  /// Parses one entry from the `import_lint.rules` map. [name] is the
  /// YAML key; [value] is the inner map containing `target`, `from`,
  /// and `except`. Throws [ArgumentException] on malformed input.
  factory Rule.fromMap(Object? name, Object? value) {
    if (name is! String) {
      throw ArgumentException(
        'name must be a String',
      );
    }

    if (name.isEmpty) {
      throw ArgumentException(
        'name must not be empty',
      );
    }

    if (value is! Map<String, Object>) {
      throw ArgumentException(
        'must be a Map<String, Object>',
      );
    }

    final constraints = <Constraint>[];

    final target =
        Constraint.fromString(ConstraintType.target, value[_targetKey]);
    constraints.add(target);

    final from = Constraint.fromString(ConstraintType.from, value[_fromKey]);
    constraints.add(from);

    final except = value[_exceptKey];
    if (except is! List<String>) {
      throw ArgumentException(
        'except must be a List<String>',
      );
    }
    final exceptRulePaths =
        except.map((e) => Constraint.fromString(ConstraintType.except, e));
    constraints.addAll(exceptRulePaths);

    return Rule(
      name,
      constraints,
    );
  }

  /// User-facing name for the rule (the YAML key under
  /// `import_lint.rules`).
  final String name;

  /// Constraints that make up the rule (`target`, `from`, and one
  /// `except` per excluded path).
  final Iterable<Constraint> constraints;

  static const _targetKey = 'target';
  static const _fromKey = 'from';
  static const _exceptKey = 'except';
}
