import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:import_lint/src/config/rule.dart';

/// It contains the [Rule] that was violated and [ImportSource]
/// which provides detailed information about the import directive that caused the violation.
class Issue {
  const Issue(
    this.rule,
    this.source,
  );
  final Rule rule;
  final ImportSource source;
}

class ImportSource {
  const ImportSource({
    required this.content,
    required this.path,
    required this.offset,
    required this.length,
    required this.startLine,
    required this.endLine,
    required this.startColumn,
    required this.endColumn,
  });

  factory ImportSource.fromImportDirective(
    ResolvedUnitResult result,
    ImportDirective directive,
  ) {
    final lineInfo = result.unit.lineInfo;
    final startLocation = lineInfo.getLocation(directive.uri.offset);
    final endLocation = lineInfo.getLocation(directive.uri.end);

    return ImportSource(
      content: directive.uri.stringValue ?? '',
      path: result.path,
      offset: directive.offset,
      length: directive.length,
      startLine: startLocation.lineNumber,
      endLine: endLocation.lineNumber,
      startColumn: startLocation.columnNumber,
      endColumn: endLocation.columnNumber,
    );
  }

  final String content;
  final String path;
  final int offset;
  final int length;
  final int startLine;
  final int endLine;
  final int startColumn;
  final int endColumn;
}
