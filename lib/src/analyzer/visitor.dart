import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/rule.dart';

class ImportLintVisitor extends SimpleAstVisitor<void> {
  ImportLintVisitor(
    this.rule,
    this.filePath,
    this.onError,
  );

  final Rule rule;
  final FilePath filePath;
  final Function(ImportDirective directive) onError;

  @override
  void visitImportDirective(ImportDirective directive) {
    final sourcePath = SourcePath.fromImportDirective(directive, filePath);

    final resolver = ConstraintResolver(rule.constraints);

    if (resolver.isViolated(filePath, sourcePath)) {
      onError(directive);
    }

    // if (!rule.matchTarget(filePath)) {
    //   return;
    // }
    // if (rule.matchExcept(sourcePath)) {
    //   return;
    // }
    // if (!rule.matchFrom(sourcePath)) {
    //   return;
    // }

    // onError(directive);
  }
}
