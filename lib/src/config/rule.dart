import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/rule_path.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

/// The Rule class defines a lint rule.
///
/// - [target] Define the file paths of the targets to be restricted
/// - [from] Define the paths that are not allowed to be used in imports
/// - [except] Define the exception paths for the 'from' rule
class Rule {
  const Rule({
    required this.name,
    required this.target,
    required this.from,
    required this.except,
  });

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

    final target = RulePath.fromString(value['target']);
    final from = RulePath.fromString(value['from']);

    final except = value['except'];
    if (except is! List<String>) {
      throw ArgumentException(
        'except must be a List<String>',
      );
    }
    final exceptRulePaths = except.map((e) => RulePath.fromString(e));

    return Rule(
      name: name,
      target: target,
      from: from,
      except: exceptRulePaths,
    );
  }

  /// Determine if the target file path is subject to import restrictions.
  bool matchTarget(FilePath path) => target.isMatch(path);

  /// Determine if the import source is restricted.
  bool matchFrom(SourcePath path) => from.isMatch(path);

  /// Determine if the import source is an exception to the restriction.
  bool matchExcept(SourcePath path) {
    final match = except.map((e) {
      return e.isMatch(path);
    }).contains(true);

    return match;
  }

  final String name;
  final RulePath target;
  final RulePath from;
  final Iterable<RulePath> except;
}
