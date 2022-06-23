import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
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
  ImportLintPlugin(ResourceProvider provider) : super(provider);

  var _filesFromSetPriorityFilesRequest = <String>[];
  late LintOptions options;

  @override
  List<String> get fileGlobsToAnalyze => const ['*.dart'];

  @override
  String get name => 'Import Linturu';

  @override
  String get version => '1.1.0-beta.0';

  @override
  String get contactInfo => 'https://github.com/kawa1214/import-lint';

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    debuglog('Analisys Driver');
    final rootPath = contextRoot.root;
    final locator =
        ContextLocator(resourceProvider: resourceProvider).locateRoots(
      includedPaths: [rootPath],
      excludedPaths: contextRoot.exclude,
      optionsFile: contextRoot.optionsFile,
    );

    if (locator.isEmpty) {
      // debuglog('Locator empty');
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

    final dartDriver = context.driver;
    runZonedGuarded(() {
      dartDriver.results.listen((event) {
        debuglog('Zoned guard');
        if (event is ResolvedUnitResult) {
          channel.sendNotification(
            plugin.AnalysisErrorsParams(
              event.path,
              [
                AnalysisError(
                    AnalysisErrorSeverity.ERROR,
                    AnalysisErrorType.LINT,
                    Location(event.path, 0, 1, 0, 1),
                    'Ae n hein mah',
                    'Zero um alfa beta')
              ],
            ).toNotification(),
          );
        }
      });
    }, (error, stack) {
      debuglog(stack.toString());
    });
    return dartDriver;
    // final config = _createConfig(dartDriver, rootPath);
    //
    // if (config == null) {
    //   return dartDriver;
    // }

    // final analysisContext = builder.createContext(contextRoot: locator.first);
    // final context = analysisContext as DriverBasedAnalysisContext;
    // final dartDriver = context.driver;
    //
    // try {
    //   for (final i in analysisContext.contextRoot.included) {
    //     final packagesFile =
    //         io.File(i.parent.canonicalizePath('${i.shortName}/.packages'));
    //     final hasPackagesFile = packagesFile.existsSync();
    //
    //     if (hasPackagesFile) {
    //       _include
    //           .add(Glob('${i.path}', recursive: true, caseSensitive: false));
    //     }
    //   }
    //
    //   final rootDirectoryPath = context.contextRoot.root.path;
    //
    //   options = LintOptions.init(
    //     directoryPath: rootDirectoryPath,
    //     optionsFile: context.contextRoot.optionsFile,
    //   );
    // } catch (e, s) {
    //   debuglog(e);
    //   debuglog(s);
    //   channel.sendNotification(
    //     plugin.PluginErrorParams(
    //       true,
    //       'Failed to load options: ${e.toString()}',
    //       s.toString(),
    //     ).toNotification(),
    //   );
    // }
    //
    // runZonedGuarded(
    //   () {
    //     dartDriver.results.listen((analysisResult) async {
    //       if (analysisResult is ResolvedUnitResult) {
    //         final result = await _check(analysisResult, context);
    //         debuglog('Error Resolved');
    //         channel.sendNotification(
    //           plugin.AnalysisErrorsParams(
    //             analysisResult.path,
    //             result,
    //           ).toNotification(),
    //         );
    //       } else if (analysisResult is ErrorsResult) {
    //         debuglog('Error result');
    //         channel.sendNotification(plugin.PluginErrorParams(
    //           false,
    //           'ErrorResult ${analysisResult}',
    //           '',
    //         ).toNotification());
    //       }
    //     });
    //   },
    //   (Object e, StackTrace stackTrace) {
    //     debuglog(e);
    //     debuglog(stackTrace);
    //     channel.sendNotification(
    //       plugin.PluginErrorParams(
    //         false,
    //         'Unexpected error: ${e.toString()}',
    //         stackTrace.toString(),
    //       ).toNotification(),
    //     );
    //   },
    // );
    // return dartDriver;
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

    final errors = await getErrors(options, context, result.path);
    return errors;
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
  final file = io.File('C:\\Users\\luaol\\plugin-report.txt')
      .openSync(mode: io.FileMode.append);
  file.writeStringSync('$value\n');
}
