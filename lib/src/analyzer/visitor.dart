import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/config/rule.dart';

/// file examining import statements. When it identifies an import statement
/// that violates a rule, it invokes the [onError] callback with the violating
class ImportLintVisitor extends SimpleAstVisitor<void> {
  ImportLintVisitor(this.rules, this.filePathResourceLocator, this.onError);

  final Iterable<Rule> rules;
  final FilePathResourceLocator filePathResourceLocator;
  final Function(ImportDirective directive, Rule rule) onError;

  @override
  void visitImportDirective(ImportDirective directive) {
    final rawUri = directive.uri.stringValue;
    if (rawUri == null || rawUri.isEmpty) return;

    final Uri uri;
    try {
      uri = Uri.parse(rawUri);
    } on FormatException {
      return;
    }

    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      uri,
      filePathResourceLocator,
    );

    for (final rule in rules) {
      final resolver = ConstraintResolver(rule.constraints);
      final isViolated = resolver.isViolated(
        filePathResourceLocator,
        importLineResourceLocator,
      );

      if (isViolated) {
        onError(directive, rule);
      }
    }
  }
}
