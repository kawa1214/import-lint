// coverage:ignore-file

import 'dart:async';

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:import_lint/import_lint.dart';

import 'dart:io' as io;

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin(ResourceProvider provider) : super(provider);

  late String rootDirectoryPath;
  late ImportLintOptions options;
  var _filesFromSetPriorityFilesRequest = <String>[];

  @override
  List<String> get fileGlobsToAnalyze => <String>['/lib/**/*.dart'];

  @override
  String get name => 'Import Lint';

  @override
  String get version => '1.0.0';

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

  List<plugin.AnalysisError> _checkFile({
    required io.File path,
    required CompilationUnit unit,
  }) {
    final analyzed =
        ImportLintAnalyze.ofFile(file: path, unit: unit, options: options);
    return analyzed.issues.map((e) => e.pluginError).toList();
  }
}
