import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
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
  /// Invalidated when the file's modification stamp changes.
  final Map<String, _CachedConfig> _configCache = {};

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

    // Skip files outside `lib/` (e.g. `bin/`, `test/`, `example/bin/`):
    // the rule's resource locator only understands `package:` URIs, which
    // only address `lib/` files. Without this guard the analyzer would
    // throw "lib path is required" and crash the analysis server.
    final FilePathResourceLocator filePathResourceLocator;
    try {
      filePathResourceLocator = FilePathResourceLocator.fromUri(
        packageName,
        Uri.file(filePath),
        Uri.directory(rootPath),
      );
    } on Object {
      return;
    }

    final visitor = ImportLintVisitor(
      config.rules,
      filePathResourceLocator,
      (directive, matchedRule) {
        reportAtOffset(
          directive.offset,
          directive.length,
          arguments: [matchedRule.name],
        );
      },
    );
    registry.addImportDirective(this, visitor);
  }

  Config? _configFor(RuleContext context) {
    final package = context.package;
    if (package == null) return null;

    final optionsFile =
        package.root.getChildAssumingFile('analysis_options.yaml');
    if (!optionsFile.exists) return null;

    final cached = _configCache[optionsFile.path];
    final currentStamp = optionsFile.modificationStamp;
    if (cached != null && cached.modificationStamp == currentStamp) {
      return cached.config;
    }

    final options = AnalysisOptions.fromFile(optionsFile);
    final config = Config.fromAnalysisOptions(options);
    _configCache[optionsFile.path] = _CachedConfig(currentStamp, config);
    return config;
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

class _CachedConfig {
  _CachedConfig(this.modificationStamp, this.config);
  final int modificationStamp;
  final Config config;
}

