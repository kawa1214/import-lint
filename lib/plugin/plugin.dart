import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
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
import 'package:glob/glob.dart';
import 'package:import_lint/import_lint.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin({required super.resourceProvider});

  LintOptions? options;

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'Import Lint';

  @override
  String get version => '1.0.0-alpha.0';

  @override
  String get contactInfo => 'https://github.com/kawa1214/import-lint';

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
      for (final i in analysisContext.contextRoot.included) {
        final packagesFile =
            io.File(i.parent.canonicalizePath('${i.shortName}/.packages'));
        final hasPackagesFile = packagesFile.existsSync();

        if (hasPackagesFile) {
          _include
              .add(Glob('${i.path}', recursive: true, caseSensitive: false));
        }
      }

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

    runZonedGuarded(
      () {
        dartDriver.results.listen((analysisResult) async {
          if (analysisResult is ResolvedUnitResult) {
            final result = await _check(analysisResult, context);

            channel.sendNotification(
              plugin.AnalysisErrorsParams(
                analysisResult.path,
                result,
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

  List<Glob> _include = [];

  Future<List<AnalysisError>> _check(
    ResolvedUnitResult result,
    DriverBasedAnalysisContext context,
  ) async {
    final included = _include.any((e) => e.matches(result.path));

    if (!included) {
      return [];
    }

    if (options == null) {
      return [];
    }

    final errors = await getErrors(options!, context, result.path);
    return errors;
  }

  /*
  @override
  void contentChanged(String path) {
    super.driverForPath(path)?.addFile(path);
  }
	*/

  /*
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
	*/

  /*
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
	*/

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    final included = _include.any((e) => e.matches(path));

    if (!included) {
      return;
    }

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
      for (final i in context.contextRoot.included) {
        final packagesFile =
            io.File(i.parent.canonicalizePath('${i.shortName}/.packages'));
        final hasPackagesFile = packagesFile.existsSync();

        if (hasPackagesFile) {
          _include
              .add(Glob('${i.path}', recursive: true, caseSensitive: false));
        }
      }

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

/*
void debuglog(Object value) {
  final file = io.File(
          '/Users/ryo/Documents/packages/import_lint_test/import-lint/log.txt')
      .openSync(mode: io.FileMode.append);
  file.writeStringSync('$value\n');
}
*/
