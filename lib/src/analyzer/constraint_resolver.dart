import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/config/constraint.dart';

/// [ConstraintResolver] class is used to determine if a particular import line
/// violates the configured constraints.
///
/// It has methods for matching target, from, and except constraints.
/// If the file path or import line matches these constraints, it is considered as violation.
class ConstraintResolver {
  const ConstraintResolver(this.constraints);
  final Iterable<Constraint> constraints;

  bool isViolated(
    ResourceLocator filePathResourceLocator,
    ResourceLocator importLineResourceLocator,
  ) {
    bool isTarget = false;
    bool isExcept = false;
    bool isFrom = false;
    for (final constraint in constraints) {
      switch (constraint.type) {
        case ConstraintType.target:
          isTarget = isTarget || _match(constraint, filePathResourceLocator);
          break;
        case ConstraintType.from:
          isFrom = isFrom || _match(constraint, importLineResourceLocator);
          break;
        case ConstraintType.except:
          isExcept = isExcept || _match(constraint, importLineResourceLocator);
          break;
      }
    }

    return isTarget && isFrom && !isExcept;
  }

  bool _match(Constraint constraint, ResourceLocator resourceLocator) {
    return constraint.package == resourceLocator.package &&
        constraint.glob.matches(resourceLocator.path);
  }
}
