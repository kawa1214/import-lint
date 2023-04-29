import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/rule.dart';

class ImportLintVisitor extends SimpleAstVisitor<void> {
  ImportLintVisitor(
    this.rules,
    this.filePath,
    this.onError,
  );

  final Iterable<Rule> rules;
  final FilePath filePath;
  final Function(ImportDirective directive, Rule rule) onError;

  @override
  void visitImportDirective(ImportDirective directive) {
    final sourcePath = SourcePath.fromImportDirective(directive, filePath);

    for (final rule in rules) {
      final resolver = ConstraintResolver(rule.constraints);
      if (resolver.isViolated(filePath, sourcePath)) {
        onError(directive, rule);
      }
    }
  }
}
