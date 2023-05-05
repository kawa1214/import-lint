import 'package:analyzer/dart/analysis/analysis_context.dart'
    show AnalysisContext;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollection;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer_plugin/plugin/plugin.dart' show ServerPlugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    show AnalysisErrorsParams, PluginErrorParams;
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin({required super.resourceProvider});

  Analyzer? analyzer;

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
    try {
      final context = analysisContext as DriverBasedAnalysisContext;
      final issues = await analyzer?.analyzeFile(context, path);
      if (issues == null) {
        return;
      }

      final severity = analyzer?.config.severity;
      if (severity == null) {
        return;
      }

      final errors = issues.map((e) => e.analysisError(severity)).toList();
      channel.sendNotification(
        AnalysisErrorsParams(
          path,
          errors,
        ).toNotification(),
      );
    } on Exception catch (e, s) {
      channel.sendNotification(PluginErrorParams(
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
      final file = context.contextRoot.optionsFile;
      final analysisOptions = AnalysisOptions.fromFile(file);
      final config = Config.fromAnalysisOptions(analysisOptions);
      analyzer = Analyzer(config);
    } catch (e, s) {
      channel.sendNotification(
        PluginErrorParams(
          true,
          'Failed to load config: ${e.toString()}',
          s.toString(),
        ).toNotification(),
      );
    }
  }
}
