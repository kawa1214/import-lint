import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:import_lint/import_lint.dart';
import 'package:import_lint/src/utils.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin(ResourceProvider provider) : super(provider);

  late String rootDirectoryPath;
  late ImportLintOptions options;
  var _filesFromSetPriorityFilesRequest = <String>[];

  @override
  List<String> get fileGlobsToAnalyze => <String>['/**/*.dart'];

  @override
  String get name => 'Import Lint';

  @override
  String get version => '1.0.0-alpha.0';

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    final optionsFile = contextRoot.optionsFile;

    final locator =
        ContextLocator(resourceProvider: resourceProvider).locateRoots(
      includedPaths: [contextRoot.root],
      excludedPaths: [
        ...contextRoot.exclude,
      ],
      optionsFile: optionsFile,
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

    final builder = ContextBuilder(
      resourceProvider: resourceProvider,
    );

    final analysisContext = builder.createContext(contextRoot: locator.first);
    final context = analysisContext as DriverBasedAnalysisContext;
    final dartDriver = context.driver;

    try {
      rootDirectoryPath = context.contextRoot.root.path;
      options = ImportLintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFilePath: optionsFile!,
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

    runZonedGuarded(
      () {
        dartDriver.results.listen((analysisResult) {
          if (analysisResult is ResolvedUnitResult) {
            final libFilePath =
                toProjectPath(path: analysisResult.path, options: options);
            final analyzed = ImportLintAnalyze.ofFile(
              filePath: analysisResult.path,
              file: io.File(libFilePath),
              unit: analysisResult.unit,
              options: options,
            );
            debuglog(['test2']);

            final errors = analyzed.issues.map((e) => e.pluginError).toList();
            channel.sendNotification(
              plugin.AnalysisErrorsParams(
                analysisResult.path,
                [
                  plugin.AnalysisError(
                    plugin.AnalysisErrorSeverity('WARNING'),
                    plugin.AnalysisErrorType.LINT,
                    plugin.Location(
                      analysisResult.path,
                      0,
                      0,
                      0,
                      0,
                    ),
                    'Found Import Lint Error:}',
                    'import_lint',
                    correction: 'Try removing the import.',
                    hasFix: false,
                  )
                ],
              ).toNotification(),
            );

            channel.sendNotification(
              plugin.AnalysisErrorsParams(
                analysisResult.path,
                errors,
              ).toNotification(),
            );
            debuglog('sended ↓');

            debuglog([analysisResult.path, libFilePath, errors.length]);
            if (errors.isNotEmpty) {
              final error = analyzed.issues.first;
              debuglog([error.location]);
            }
            /*
            final path = analysisResult.path;

            final errors = _checkFile(
              path: io.File(path),
              unit: analysisResult.unit,
            );

            channel.sendNotification(
              plugin.AnalysisErrorsParams(
                path,
                errors,
              ).toNotification(),
            );
						*/
          } else if (analysisResult is ErrorsResult) {
            channel.sendNotification(plugin.PluginErrorParams(
              false,
              'ErrorResult ${analysisResult}',
              '',
            ).toNotification());
          }
        });
      },
      (Object e, StackTrace stackTrace) {
        channel.sendNotification(
          plugin.PluginErrorParams(
            false,
            'Unexpected error: ${e.toString()}',
            stackTrace.toString(),
          ).toNotification(),
        );
      },
    );
    return dartDriver;
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
    return result;
  }

  void _updatePriorityFiles() {
    final filesToFullyResolve = {
      ..._filesFromSetPriorityFilesRequest,
      for (final driver2 in driverMap.values)
        ...(driver2 as AnalysisDriver).addedFiles,
    };

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

void debuglog(Object value) {
  final file = io.File(
          '/Users/ryo/Documents/packages/import_lint_test/import-lint/log.txt')
      .openSync(mode: io.FileMode.append);
  file.writeStringSync('$value\n');
}
