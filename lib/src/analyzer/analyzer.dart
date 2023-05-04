import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';

class Analyzer {
  const Analyzer(this.config);

  final Config config;

  Future<Iterable<Issue>> analyzeFile(
    DriverBasedAnalysisContext context,
    String path,
  ) async {
    final result = await context.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      throw InternalException('result is not ResolvedUnitResult');
    }

    final package = this._package(context, path);
    final rootPath = this._rootDirectoryPath(context);

    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      package,
      Uri.file(result.path),
      Uri.directory(rootPath),
    );

    final issues = <Issue>[];
    result.unit.visitChildren(ImportLintVisitor(
      config.rules,
      filePathResourceLocator,
      (directive, rule) {
        final source = ImportSource.fromImportDirective(result, directive);
        issues.add(Issue(rule, source));
      },
    ));

    return issues;
  }

  Future<Iterable<Issue>> analyzeFiles(
    DriverBasedAnalysisContext context,
    Iterable<String> paths,
  ) async {
    final tasks = paths.map((e) => analyzeFile(context, e));
    final results = await Future.wait(tasks);
    final issues = results.expand((e) => e);
    return issues;
  }

  String _rootDirectoryPath(DriverBasedAnalysisContext context) {
    return context.contextRoot.root.parent.path;
  }

  String _package(
    DriverBasedAnalysisContext context,
    String path,
  ) {
    final workspacePackage = context.contextRoot.workspace.findPackageFor(path);
    if (workspacePackage is! PubWorkspacePackage) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }

    final package = workspacePackage.pubspec?.name?.value.text;
    if (package == null) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }

    return package;
  }
}
