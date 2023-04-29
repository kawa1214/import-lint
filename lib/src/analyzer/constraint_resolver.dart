import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/constraint.dart';

class ConstraintResolver {
  const ConstraintResolver(this.constraints);
  final Iterable<Constraint> constraints;

  bool isViolated(FilePath file, SourcePath source) {
    for (final constraint in constraints) {
      if (constraint is TargetConstraint) {
        if (!_matchTarget(constraint, file)) {
          return false;
        }
      } else if (constraint is ExceptConstraint) {
        if (_matchExcept(constraint, source)) {
          return false;
        }
      } else if (constraint is FromConstraint) {
        if (_matchFrom(constraint, source)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _matchTarget(TargetConstraint constraint, FilePath path) =>
      _match(constraint, path);

  bool _matchFrom(FromConstraint constraint, SourcePath path) =>
      _match(constraint, path);

  bool _matchExcept(ExceptConstraint constraint, SourcePath path) =>
      _match(constraint, path);

  bool _match(Constraint constraint, Path path) {
    return constraint.package == path.package &&
        constraint.glob.matches(path.path);
  }
}
