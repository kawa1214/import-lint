import 'package:analyzer/dart/analysis/analysis_context.dart'
    show AnalysisContext;
import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';

/// [DriverBasedAnalysisContextAnalyzer] class is responsible for analyzing given file(s)
/// and finding issues based on configured rules.
///
/// It uses [DriverBasedAnalysisContext] and path(s) to analyze file(s),
/// and generates [Issue] objects if any violations are found.
class DriverBasedAnalysisContextAnalyzer implements Analyzer {
  DriverBasedAnalysisContextAnalyzer(
    this._context,
  ) : config = _createConfig(_context);
  final AnalysisContext _context;
  final Config config;

  @override
  Future<Iterable<Issue>> analyzeFile(
    String path,
  ) async {
    final result = await _context.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      throw InternalException('result is not ResolvedUnitResult');
    }

    final package = this._packageFromPath(path);
    final rootPath = this._rootDirectoryPath();

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

  @override
  Future<Iterable<Issue>> analyzeFiles(Iterable<String> paths) async {
    final tasks = paths.map((e) => analyzeFile(e));
    final results = await Future.wait(tasks);
    final issues = results.expand((e) => e);
    return issues;
  }

  @override
  Iterable<String> analyzedFiles() {
    final paths = _context.contextRoot.analyzedFiles();
    return paths.where((path) => path.endsWith('.dart'));
  }

  String _packageFromPath(
    String path,
  ) {
    final workspacePackage =
        _context.contextRoot.workspace.findPackageFor(path);
    if (workspacePackage is! PubWorkspacePackage) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }

    final package = workspacePackage.pubspec?.name?.value.text;
    if (package == null) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }

    return package;
  }

  String _rootDirectoryPath() {
    return _context.contextRoot.root.parent.path;
  }

  static Config _createConfig(AnalysisContext context) {
    final optionsFile = context.contextRoot.optionsFile;
    final analysisOptions = AnalysisOptions.fromFile(optionsFile);
    return Config.fromAnalysisOptions(analysisOptions);
  }
}

abstract class Analyzer {
  const Analyzer(this.config); // coverage:ignore-line
  final Config config;

  Future<Iterable<Issue>> analyzeFile(String path);
  Future<Iterable<Issue>> analyzeFiles(Iterable<String> paths);
  Iterable<String> analyzedFiles();
}
