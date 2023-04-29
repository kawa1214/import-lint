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

enum ConstraintType {
  target,
  from,
  except,
}

extension ConstraintTypeExtension on ConstraintType {
  String get key {
    switch (this) {
      case ConstraintType.target:
        return 'target';
      case ConstraintType.from:
        return 'from';
      case ConstraintType.except:
        return 'except';
    }
  }
}

abstract class Constraint {
  const Constraint(this.package, this.glob); // coverage:ignore-line

  factory Constraint.fromString(ConstraintType type, Object? value) {
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
      case ConstraintType.target:
        return TargetConstraint(package, glob);
      case ConstraintType.from:
        return FromConstraint(package, glob);
      case ConstraintType.except:
        return ExceptConstraint(package, glob);
    }
  }

  final String package;
  final Glob glob;
}
