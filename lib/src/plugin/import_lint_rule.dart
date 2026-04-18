import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:analyzer/error/error.dart' show DiagnosticCode, LintCode;
import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:yaml/yaml.dart' show YamlMap, loadYamlNode;

/// Single `AnalysisRule` that wraps the existing [ImportLintVisitor] and
/// reports violations to the analysis server framework.
///
/// Configuration (`import_lint:` block in `analysis_options.yaml`) is loaded
/// lazily per context-root and cached for subsequent file analyses in that root.
class ImportLintRule extends AnalysisRule {
  ImportLintRule()
      : super(
          name: lintName,
          description: _description,
        );

  static const String lintName = 'import_lint';
  static const String _description =
      'Flags imports that violate the rules declared under `import_lint:` '
      'in analysis_options.yaml.';

  static const LintCode code = LintCode(
    lintName,
    'Found Import Lint Error: {0}',
    correctionMessage: 'Try removing the import.',
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  /// Cached configs keyed by `analysis_options.yaml` absolute path.
  final Map<String, Config> _configCache = {};

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final config = _configFor(context);
    if (config == null) return;

    final package = context.package;
    if (package == null) return;

    final packageName = _readPackageName(
      package.root.getChildAssumingFile('pubspec.yaml'),
    );
    if (packageName == null) return;

    final filePath = context.definingUnit.file.path;
    final rootPath = package.root.parent.path;

    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      packageName,
      Uri.file(filePath),
      Uri.directory(rootPath),
    );

    final visitor = _RuleVisitor(
      rule: this,
      config: config,
      filePathResourceLocator: filePathResourceLocator,
    );
    registry.addImportDirective(this, visitor);
  }

  Config? _configFor(RuleContext context) {
    final package = context.package;
    if (package == null) return null;

    final optionsFile =
        package.root.getChildAssumingFile('analysis_options.yaml');
    if (!optionsFile.exists) return null;

    return _configCache.putIfAbsent(optionsFile.path, () {
      final options = AnalysisOptions.fromFile(optionsFile);
      return Config.fromAnalysisOptions(options);
    });
  }

  /// Reads the package name from the given [pubspecFile].
  ///
  /// Returns `null` if the file does not exist or does not contain a name.
  static String? _readPackageName(File pubspecFile) {
    if (!pubspecFile.exists) return null;
    final content = pubspecFile.readAsStringSync();
    final node = loadYamlNode(content);
    if (node is! YamlMap) return null;
    final name = node['name'];
    if (name is! String) return null;
    return name;
  }
}

class _RuleVisitor extends SimpleAstVisitor<void> {
  _RuleVisitor({
    required this.rule,
    required this.config,
    required this.filePathResourceLocator,
  });

  final ImportLintRule rule;
  final Config config;
  final FilePathResourceLocator filePathResourceLocator;

  @override
  void visitImportDirective(ImportDirective directive) {
    ImportLintVisitor(
      config.rules,
      filePathResourceLocator,
      (d, matchedRule) {
        rule.reportAtOffset(
          d.offset,
          d.length,
          arguments: [matchedRule.name],
        );
      },
    ).visitImportDirective(directive);
  }
}
