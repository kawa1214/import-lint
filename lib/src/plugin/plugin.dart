import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:import_lint/src/plugin/import_lint_rule.dart';

class ImportLintPlugin extends Plugin {
  @override
  String get name => 'import_lint';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(ImportLintRule());
  }
}
