import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin
    show AnalysisErrorsParams, PluginErrorParams;
import 'package:import_lint/import_lint.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin({required super.resourceProvider});

  LintOptions? options;

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'Import Lint';

  // https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/lib/protocol/protocol_constants.dart
  @override
  String get version => '1.33.4';

  @override
  String get contactInfo => 'https://github.com/kawa1214/import-lint';

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    if (options == null) {
      return;
    }

    try {
      final context = analysisContext as DriverBasedAnalysisContext;
      final errors = await getErrors(options!, context, path);

      channel.sendNotification(
        plugin.AnalysisErrorsParams(
          path,
          errors,
        ).toNotification(),
      );
    } on Exception catch (e, s) {
      channel.sendNotification(plugin.PluginErrorParams(
        false,
        'ErrorResult ${e.toString()}',
        s.toString(),
      ).toNotification());
    }
  }

  @override
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) {
    contextCollection.contexts.forEach(_initOptions);

    return super
        .afterNewContextCollection(contextCollection: contextCollection);
  }

  Future<void> _initOptions(AnalysisContext context) async {
    try {
      final rootDirectoryPath = context.contextRoot.root.path;

      options = LintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFile: context.contextRoot.optionsFile,
      );
    } catch (e, s) {
      channel.sendNotification(
        plugin.PluginErrorParams(
          true,
          'Failed to load options: ${e.toString()}',
          s.toString(),
        ).toNotification(),
      );
    }
  }
}

// void debuglog(Object value) {
//   final file = io.File(
//           '/Users/ryo/Documents/packages/import_lint_test/import-lint/log.txt')
//       .openSync(mode: io.FileMode.append);
//   file.writeStringSync('$value\n');
// }
