import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/config/constraint.dart';

class ConstraintResolver {
  const ConstraintResolver(this.constraints);
  final Iterable<Constraint> constraints;

  bool isViolated(
    FilePathResourceLocator filePathResourceLocator,
    ImportLineResourceLocator importLineResourceLocator,
  ) {
    bool isTarget = false;
    bool isExcept = false;
    bool isFrom = false;
    for (final constraint in constraints) {
      switch (constraint.type) {
        case ConstraintType.target:
          if (_matchTarget(constraint, filePathResourceLocator)) {
            isTarget = true;
          }
          break;
        case ConstraintType.from:
          if (_matchFrom(constraint, importLineResourceLocator)) {
            isFrom = true;
          }
          break;
        case ConstraintType.except:
          if (_matchExcept(constraint, importLineResourceLocator)) {
            isExcept = true;
          }
          break;
      }
    }

    if (isTarget && isFrom && !isExcept) {
      return true;
    }
    return false;
  }

  bool _matchTarget(Constraint constraint,
          FilePathResourceLocator filePathResourceLocator) =>
      _match(constraint, filePathResourceLocator);

  bool _matchFrom(Constraint constraint,
          ImportLineResourceLocator importLineResourceLocator) =>
      _match(constraint, importLineResourceLocator);

  bool _matchExcept(Constraint constraint,
          ImportLineResourceLocator filePathResourceLocator) =>
      _match(constraint, filePathResourceLocator);

  bool _match(Constraint constraint, ResourceLocator resourceLocator) {
    return constraint.package == resourceLocator.package &&
        constraint.glob.matches(resourceLocator.path);
  }
}
