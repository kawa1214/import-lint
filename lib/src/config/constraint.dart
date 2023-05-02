import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// Define the file paths of the targets to be restricted
class TargetConstraint implements Constraint {
  const TargetConstraint(this.package, this.glob);
  final String package;
  final Glob glob;
}

/// Define the paths that are not allowed to be used in imports
class FromConstraint implements Constraint {
  const FromConstraint(this.package, this.glob);
  final String package;
  final Glob glob;
}

/// Define the exception paths for the 'from' rule
class ExceptConstraint implements Constraint {
  const ExceptConstraint(this.package, this.glob);
  final String package;
  final Glob glob;
}

abstract class Constraint {
  const Constraint(this.package, this.glob); // coverage:ignore-line

  factory Constraint.fromString(Type type, Object? value) {
    if (value is! String) {
      throw ArgumentException(
        'must be a String',
      );
    }

    final package = RegExp('(?<=package:).*?(?=\/)').stringMatch(value);
    if (package == null) {
      throw ArgumentException(
        'package is required',
      );
    }

    final path = value.replaceFirst('package:$package/', '');
    final glob = Glob(path, recursive: true, caseSensitive: false);

    switch (type) {
      case TargetConstraint:
        return TargetConstraint(package, glob);
      case FromConstraint:
        return FromConstraint(package, glob);
      case ExceptConstraint:
        return ExceptConstraint(package, glob);
      default:
        throw ArgumentException(
          'Unsupported ConstraintType',
        );
    }
  }

  final String package;
  final Glob glob;
}
