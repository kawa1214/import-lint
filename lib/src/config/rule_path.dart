import 'package:glob/glob.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// Define package name and Glob pattern.
class RulePath {
  const RulePath(this.package, this.pattern);

  factory RulePath.fromString(Object? value) {
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
    final pattern = Glob(path, recursive: true, caseSensitive: false);

    return RulePath(package, pattern);
  }

  final String package;
  final Glob pattern;
}
