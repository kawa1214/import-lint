import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// Define the type of constraint
/// - [target] Define the file paths of the targets to be restricted
/// - [from] Define the paths that are not allowed to be used in imports
/// - [except] Define the exception paths for the 'from' rule
enum ConstraintType {
  target,
  from,
  except,
}

class Constraint {
  const Constraint(this.type, this.package, this.glob); // coverage:ignore-line

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
    return Constraint(type, package, glob);
  }

  final ConstraintType type;
  final String package;
  final Glob glob;
}
