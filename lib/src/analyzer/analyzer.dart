import 'package:analyzer/dart/analysis/analysis_context.dart'
    show AnalysisContext;
import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:analyzer/workspace/workspace.dart' show WorkspacePackage;
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYamlNode;

/// [DriverBasedAnalysisContextAnalyzer] class is responsible for analyzing given file(s)
/// and finding issues based on configured rules.
///
/// It uses [DriverBasedAnalysisContext] and path(s) to analyze file(s),
/// and generates [Issue] objects if any violations are found.
class DriverBasedAnalysisContextAnalyzer implements Analyzer {
  DriverBasedAnalysisContextAnalyzer(this._context)
    : config = _createConfig(_context);
  final AnalysisContext _context;
  final Config config;

  @override
  Future<Iterable<Issue>> analyzeFile(String path) async {
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
    result.unit.visitChildren(
      ImportLintVisitor(config.rules, filePathResourceLocator, (
        directive,
        rule,
      ) {
        final source = ImportSource.fromImportDirective(
          result.unit.lineInfo,
          directive,
        );
        issues.add(Issue(result.path, rule, source));
      }),
    );

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

  String _packageFromPath(String path) {
    final found = _context.contextRoot.workspace.findPackageFor(path);
    if (found is! WorkspacePackage) {
      throw InternalException('workspacePackage is not WorkspacePackage');
    }
    final workspacePackage = found as WorkspacePackage;

    final packageName = _readPackageName(
      workspacePackage.root.getChildAssumingFile('pubspec.yaml'),
    );
    if (packageName == null) {
      throw InternalException('pubspec.yaml not found or missing "name" field');
    }

    return packageName;
  }

  static String? _readPackageName(File pubspecFile) {
    if (!pubspecFile.exists) return null;
    final content = pubspecFile.readAsStringSync();
    final node = loadYamlNode(content);
    if (node is! YamlMap) return null;
    final name = node['name'];
    if (name is! String) return null;
    return name;
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

/// High-level façade for analyzing Dart source files against the
/// configured import rules.
///
/// Implementations are responsible for resolving Dart sources, walking
/// the AST for `import` directives, and producing [Issue] objects for
/// every violation. The default implementation is
/// [DriverBasedAnalysisContextAnalyzer], which adapts the analyzer
/// package's `AnalysisContext`.
abstract class Analyzer {
  /// Subclasses must call this constructor with the parsed [config]
  /// that drives the lint checks.
  const Analyzer(this.config); // coverage:ignore-line

  /// The parsed `import_lint:` block from `analysis_options.yaml`.
  final Config config;

  /// Analyzes a single Dart file at the given absolute [path] and
  /// returns the issues that were found.
  Future<Iterable<Issue>> analyzeFile(String path);

  /// Analyzes every absolute path in [paths] (concurrently) and
  /// returns a flat sequence of issues across all files.
  Future<Iterable<Issue>> analyzeFiles(Iterable<String> paths);

  /// Returns every Dart file the underlying analysis context is
  /// configured to analyze.
  Iterable<String> analyzedFiles();
}
