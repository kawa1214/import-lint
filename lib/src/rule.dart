import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
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

Future<List<AnalysisError>> getErrors(
  LintOptions options,
  DriverBasedAnalysisContext context,
  String path,
) async {
  final result =
      await context.currentSession.getResolvedUnit(path) as ResolvedUnitResult;

  final workspace = context.contextRoot.workspace;
  final package = workspace.findPackageFor(path);

  if (package is! PubWorkspacePackage) return [];

  final pubspec = package.pubspec;

  if (pubspec == null) return [];
  final packageName = pubspec.name?.value.text;

  if (packageName == null) return [];

  final directoryPath = package.root;
  final errors = <AnalysisError>[];

  for (final rule in options.rules.value) {
    result.unit.visitChildren(
      _ImportLintVisitor(
        rule,
        result.path,
        packageName,
        directoryPath,
        result.unit,
        (error) {
          errors.add(error);
        },
      ),
    );
  }

  return errors;
}

class _ImportSource {
  const _ImportSource({
    required this.package,
    required this.source,
  });
  final String package;
  final String source;
}

class _ImportLintVisitor extends SimpleAstVisitor<void> {
  _ImportLintVisitor(
    this.ruleOption,
    this.filePath,
    this.packageName,
    this.directoryPath,
    this.unit,
    this.onError,
  );

  final RuleOption ruleOption;
  final String filePath;
  final String packageName;
  final String directoryPath;
  final CompilationUnit unit;
  final Function(AnalysisError) onError;

  _ImportSource? _toImportSource(ImportDirective node) {
    final encodedSelectedSourceUri = node.selectedSource?.uri.toString();

    if (encodedSelectedSourceUri == null) {
      return null;
    }

    final selectedSource = Uri.decodeFull(encodedSelectedSourceUri);

    final package = _packageFromSelectedSource(selectedSource);
    final source = _sourceFromSelectedSource(selectedSource, package);

    return _ImportSource(package: package, source: source);
  }

  String _packageFromSelectedSource(String source) {
    late String package;
    final packageRegExpResult =
        RegExp('(?<=package:).*?(?=\/)').stringMatch(source);
    if (packageRegExpResult != null) {
      package = packageRegExpResult;
    } else {
      package = packageName;
    }

    return package;
  }

  String _sourceFromSelectedSource(String source, String package) {
    return source.replaceFirst('package:$package/', '');
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final importSource = _toImportSource(node);

    if (importSource == null) {
      return;
    }

    final libFilePath = toPackagePath(filePath);

    if (!ruleOption.targetFilePath.matches(libFilePath)) {
      return;
    }

    for (final notAllowImportRule in ruleOption.notAllowImports) {
      if (notAllowImportRule.path.matches(importSource.source)) {
        final isIgnore = ruleOption.excludeImports.map((e) {
          final matchIgnore = e.path.matches(importSource.source);
          final equalPackage =
              importSource.package == e.fixedPackage(packageName);

          return matchIgnore && equalPackage;
        }).contains(true);

        if (isIgnore) {
          continue;
        }

        if (importSource.package !=
            notAllowImportRule.fixedPackage(packageName)) {
          continue;
        }

        final lineInfo = unit.lineInfo;
        final loc = lineInfo.getLocation(node.uri.offset);
        final locEnd = lineInfo.getLocation(node.uri.end);

        final error = AnalysisError(
          AnalysisErrorSeverity('WARNING'),
          AnalysisErrorType.LINT,
          Location(
            filePath,
            node.offset,
            node.length,
            loc.lineNumber,
            loc.columnNumber,
            endLine: locEnd.lineNumber,
            endColumn: locEnd.columnNumber,
          ),
          'Found Import Lint Error: ${ruleOption.name}',
          'import_lint',
          correction: 'Try removing the import.',
          hasFix: false,
        );

        onError(error);
      }
    }
  }
}
