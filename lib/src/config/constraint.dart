import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// Define the type of constraint
/// - [target] Define the file paths of the targets to be restricted
/// - [from] Define the paths that are not allowed to be used in imports
/// - [except] Define the exception paths for the 'from' rule
enum ConstraintType { target, from, except }

/// A constraint that specifies conditions for a lint rule, such as a target or a source.
class Constraint {
  /// Builds a constraint explicitly. Use [Constraint.fromString] when
  /// parsing a `package:foo/bar/*.dart`-style path from YAML.
  const Constraint(this.type, this.package, this.glob);

  /// Parses a `package:foo/bar/*.dart` string into a [Constraint].
  /// Throws [ArgumentException] when the input is not a string or
  /// does not contain a `package:` prefix.
  factory Constraint.fromString(ConstraintType type, Object? value) {
    if (value is! String) {
      throw ArgumentException('must be a String');
    }

    final package = _packageRegExp.stringMatch(value);
    if (package == null) {
      throw ArgumentException('package is required');
    }

    final path = value.replaceFirst('package:$package/', '');
    final glob = Glob(path, recursive: true, caseSensitive: false);
    return Constraint(type, package, glob);
  }

  static final _packageRegExp = RegExp('(?<=package:).*?(?=\/)');

  /// Whether this constraint matches the import target, source, or
  /// an exception to the source.
  final ConstraintType type;

  /// The Dart package name extracted from the original
  /// `package:<name>/...` string.
  final String package;

  /// Glob compiled from the path portion (after `package:<name>/`).
  /// Used to match individual file paths within [package].
  final Glob glob;
}
