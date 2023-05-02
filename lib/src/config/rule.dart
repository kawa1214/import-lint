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

    final target = Constraint.fromString(TargetConstraint, value[_targetKey]);
    constraints.add(target);

    final from = Constraint.fromString(FromConstraint, value[_fromKey]);
    constraints.add(from);

    final except = value[_exceptKey];
    if (except is! List<String>) {
      throw ArgumentException(
        'except must be a List<String>',
      );
    }
    final exceptRulePaths =
        except.map((e) => Constraint.fromString(ExceptConstraint, e));
    constraints.addAll(exceptRulePaths);

    return Rule(
      name,
      constraints,
    );
  }

  final String name;
  final Iterable<Constraint> constraints;

  static const _targetKey = 'target';
  static const _fromKey = 'from';
  static const _exceptKey = 'except';
}
