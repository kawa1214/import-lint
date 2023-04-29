import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

class Rule {
  const Rule(this.name, this.constraints);

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

    final constraints = <Constraint>[];

    final target = Constraint.fromString(
        ConstraintType.target, value[ConstraintType.target.key]);
    constraints.add(target);

    final from = Constraint.fromString(
        ConstraintType.from, value[ConstraintType.from.key]);
    constraints.add(from);

    final except = value[ConstraintType.except.key];
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

  final String name;
  final Iterable<Constraint> constraints;
}
