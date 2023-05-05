import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:analyzer/src/dart/element/element.dart'
    show DirectiveUriWithRelativeUriImpl;
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/config/rule.dart';

/// file examining import statements. When it identifies an import statement
/// that violates a rule, it invokes the [onError] callback with the violating
class ImportLintVisitor extends SimpleAstVisitor<void> {
  ImportLintVisitor(
    this.rules,
    this.filePathResourceLocator,
    this.onError,
  );

  final Iterable<Rule> rules;
  final FilePathResourceLocator filePathResourceLocator;
  final Function(ImportDirective directive, Rule rule) onError;

  @override
  void visitImportDirective(ImportDirective directive) {
    final uri = directive.element?.uri;

    if (uri is! DirectiveUriWithRelativeUriImpl) {
      return;
    }

    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      uri.relativeUri,
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
