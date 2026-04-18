import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/source/line_info.dart' show LineInfo;
import 'package:import_lint/src/config/rule.dart';

/// It contains the [Rule] that was violated and [ImportSource]
/// which provides detailed information about the import directive that caused the violation.
class Issue {
  /// Creates an issue for the given file [path], the matched [rule],
  /// and the offending import [source].
  const Issue(this.path, this.rule, this.source);

  /// Absolute path of the Dart file in which the violation was
  /// reported.
  final String path;

  /// The lint rule that flagged the import.
  final Rule rule;

  /// Location and content of the offending `import` directive.
  final ImportSource source;
}

/// Location, length, and content of an `import` directive that
/// triggered an [Issue].
class ImportSource {
  /// Creates an import-source descriptor with explicit values. Most
  /// callers should use [ImportSource.fromImportDirective].
  const ImportSource({
    required this.content,
    required this.offset,
    required this.length,
    required this.startLine,
    required this.endLine,
    required this.startColumn,
    required this.endColumn,
  });

  /// Builds an [ImportSource] from the analyzer's [LineInfo] and
  /// [ImportDirective] AST node.
  factory ImportSource.fromImportDirective(
    LineInfo lineInfo,
    ImportDirective directive,
  ) {
    final startLocation = lineInfo.getLocation(directive.uri.offset);
    final endLocation = lineInfo.getLocation(directive.uri.end);

    return ImportSource(
      content: directive.uri.stringValue ?? '',
      offset: directive.offset,
      length: directive.length,
      startLine: startLocation.lineNumber,
      endLine: endLocation.lineNumber,
      startColumn: startLocation.columnNumber,
      endColumn: endLocation.columnNumber,
    );
  }

  /// String value of the import URI (the part inside the quotes).
  final String content;

  /// Absolute offset of the directive within the source file.
  final int offset;

  /// Length of the directive in characters.
  final int length;

  /// 1-based line where the URI begins.
  final int startLine;

  /// 1-based line where the URI ends.
  final int endLine;

  /// 1-based column where the URI begins.
  final int startColumn;

  /// 1-based column where the URI ends.
  final int endColumn;
}
