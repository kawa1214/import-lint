import 'dart:async';

import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin
    show
        AnalysisErrorsParams,
        ContextRoot,
        PluginErrorParams,
        AnalysisSetPriorityFilesResult,
        AnalysisSetPriorityFilesParams,
        AnalysisSetContextRootsResult,
        AnalysisSetContextRootsParams;
import 'package:import_lint/src/infra/error_collector.dart';
import 'package:import_lint/src/main/create_error_collector.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin(ResourceProvider provider) : super(provider);

  var _filesFromSetPriorityFilesRequest = <String>[];

  @override
  List<String> get fileGlobsToAnalyze => const ['*.dart'];

  @override
  String get name => 'Import Lint';

  @override
  String get version => '1.0.0-alpha.0';

  @override
  String get contactInfo => 'https://github.com/kawa1214/import-lint';

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    final rootPath = contextRoot.root;

    final locator =
        ContextLocator(resourceProvider: resourceProvider).locateRoots(
      includedPaths: [rootPath],
      excludedPaths: contextRoot.exclude,
      optionsFile: contextRoot.optionsFile,
    );

    if (locator.isEmpty) {
      final error = StateError('Unexpected empty context');
      channel.sendNotification(plugin.PluginErrorParams(
        true,
        error.message,
        error.stackTrace.toString(),
      ).toNotification());

      throw error;
    }

    final builder = ContextBuilderImpl(
      resourceProvider: resourceProvider,
    );

    final context = builder.createContext(
      contextRoot: locator.first,
    );

    final ErrorCollector errorCollector = createCollector(context);

    final dartDriver = context.driver;
    runZonedGuarded(() {
      dartDriver.results.listen((event) async {
        if (event is ResolvedUnitResult) {
          final result = await _check(errorCollector, dartDriver, event);
          channel.sendNotification(plugin.AnalysisErrorsParams(
            event.path,
            result,
          ).toNotification());
        } else if (event is ErrorsResult) {
          channel.sendNotification(plugin.PluginErrorParams(
            false,
            'ErrorResult ${event}',
            '',
          ).toNotification());
        }
      });
    }, (error, stack) {
      channel.sendNotification(plugin.PluginErrorParams(
        false,
        'Unexpected error: ${error.toString()}',
        stack.toString(),
      ).toNotification());
    });
    return dartDriver;
  }

  Future<List<AnalysisError>> _check(
    ErrorCollector errorCollector,
    AnalysisDriver driver,
    ResolvedUnitResult result,
  ) async {
    if (driver.analysisContext?.contextRoot.isAnalyzed(result.path) ?? false) {
      final errors = await errorCollector.collectErrorsFor(result.path);
      return errors;
    }
    return [];
  }

  @override
  void contentChanged(String path) {
    super.driverForPath(path)?.addFile(path);
  }

  @override
  Future<plugin.AnalysisSetPriorityFilesResult> handleAnalysisSetPriorityFiles(
    plugin.AnalysisSetPriorityFilesParams parameters,
  ) async {
    _filesFromSetPriorityFilesRequest = parameters.files;
    _updatePriorityFiles();

    return plugin.AnalysisSetPriorityFilesResult();
  }

  @override
  Future<plugin.AnalysisSetContextRootsResult> handleAnalysisSetContextRoots(
    plugin.AnalysisSetContextRootsParams parameters,
  ) async {
    final result = await super.handleAnalysisSetContextRoots(parameters);
    // The super-call adds files to the driver, so we need to prioritize them so they get analyzed.
    _updatePriorityFiles();

    return result;
  }

  /// AnalysisDriver doesn't fully resolve files that are added via `addFile`; they need to be either explicitly requested
  /// via `getResult`/etc, or added to `priorityFiles`.
  ///
  /// This method updates `priorityFiles` on the driver to include:
  ///
  /// - Any files prioritized by the analysis server via [handleAnalysisSetPriorityFiles]
  /// - All other files the driver has been told to analyze via addFile (in [ServerPlugin.handleAnalysisSetContextRoots])
  ///
  /// As a result, [_processResult] will get called with resolved units, and thus all of our diagnostics
  /// will get run on all files in the repo instead of only the currently open/edited ones!
  void _updatePriorityFiles() {
    final filesToFullyResolve = {
      // Ensure these go first, since they're actually considered priority; ...
      ..._filesFromSetPriorityFilesRequest,

      // ... all other files need to be analyzed, but don't trump priority
      for (final driver2 in driverMap.values)
        ...(driver2 as AnalysisDriver).addedFiles,
    };

    // From ServerPlugin.handleAnalysisSetPriorityFiles.
    final filesByDriver = <AnalysisDriverGeneric, List<String>>{};
    for (final file in filesToFullyResolve) {
      final contextRoot = contextRootContaining(file);
      if (contextRoot != null) {
        final driver = driverMap[contextRoot];
        if (driver != null) {
          filesByDriver.putIfAbsent(driver, () => <String>[]).add(file);
        }
      }
    }
    filesByDriver.forEach((driver, files) {
      driver.priorityFiles = files;
    });
  }
}

// void debuglog(Object value) {
//   final file = io.File('C:\\Users\\luaol\\plugin-report.txt')
//       .openSync(mode: io.FileMode.append);
//   file.writeStringSync('$value\n');
// }
