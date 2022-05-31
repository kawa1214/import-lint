import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:import_lint/import_lint.dart';
import 'package:import_lint/src/rule.dart';
import 'package:import_lint/src/utils.dart';

export 'package:analyzer/dart/element/type_system.dart';
export 'package:analyzer/src/dart/ast/token.dart';
export 'package:analyzer/src/dart/error/lint_codes.dart';
export 'package:analyzer/src/dart/resolver/exit_detector.dart';
export 'package:analyzer/src/generated/engine.dart' show AnalysisErrorInfo;
export 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
export 'package:analyzer/src/lint/linter.dart'
    show
        DartLinter,
        LintRule,
        Group,
        Maturity,
        LinterContext,
        LinterOptions,
        LintFilter,
        NodeLintRegistry,
        NodeLintRule;
export 'package:analyzer/src/lint/pub.dart' show PubspecVisitor, PSEntry;
export 'package:analyzer/src/lint/util.dart' show Spelunker;
export 'package:analyzer/src/services/lint.dart' show lintRegistry;
export 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;

class ImportLintRule extends LintRule {
  ImportLintRule(this.ruleOption)
      : super(
            name: 'import_lint_${ruleOption.name}',
            description: 'Found Import Lint Error: ${ruleOption.name}',
            details: 'Found Import Lint Error: ${ruleOption.name}',
            group: Group.style);

  final RuleOption ruleOption;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final package = context.package;
    if (package is! PubWorkspacePackage) return;

    final pubspec = package.pubspec;
    if (pubspec == null) return;
    final packageName = pubspec.name?.value.text;
    if (packageName == null) return;

    final directoryPath = package.root;

    final visitor =
        _ImportLintVisitor(this, context, packageName, directoryPath);
    registry.addImportDirective(this, visitor);
  }
}

class _ImportLintVisitor extends SimpleAstVisitor<void> {
  _ImportLintVisitor(
    this.rule,
    this.context,
    this.packageName,
    this.directoryPath,
  );

  final ImportLintRule rule;
  final LinterContext context;
  final String packageName;
  final String directoryPath;

  @override
  void visitImportDirective(ImportDirective node) {
    final visitor = _FileVisitor();
    context.currentUnit.unit.accept(visitor);
    final filePath = visitor.filePath;

    if (filePath == null) {
      return;
    }

    final pathSource = node.selectedSource?.fullName;
    if (pathSource == null) {
      return;
    }

    final libPath = toPackagePath(
      pathSource,
      directoryPath,
    );

    final importContent = node.selectedUriContent;

    if (importContent == null) {
      return;
    }

    final libFilePath = toPackagePath(filePath, directoryPath);

    if (!rule.ruleOption.targetFilePath.matches(libFilePath)) {
      return;
    }

    late String importPackageName;
    late String importValue;

    final packageRegExpResult =
        RegExp('(?<=package:).*?(?=\/)').stringMatch(importContent);
    if (packageRegExpResult != null) {
      importPackageName = packageRegExpResult;
    } else {
      importPackageName = packageName;
    }

    if (importPackageName == packageName) {
      importValue = libPath;
    } else {
      importValue =
          importContent.replaceFirst('package:$importPackageName/', '');
    }

    //debuglog([importPackageName, importValue]);

    for (final notAllowImportRule in rule.ruleOption.notAllowImports) {
      if (notAllowImportRule.path.matches(importValue)) {
        final isIgnore = rule.ruleOption.excludeImports
            .map((e) => e.path.matches(importValue))
            .contains(true);

        if (isIgnore) {
          continue;
        }

        rule.reportLint(node.uri);
      }
    }
  }
}

class _FileVisitor extends SimpleAstVisitor<void> {
  _FileVisitor();
  String? filePath = null;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    filePath = node.declaredElement?.source.fullName;
  }
}
