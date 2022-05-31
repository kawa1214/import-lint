import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
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
import 'package:import_lint/src/cli.dart';
import 'package:import_lint/src/rule.dart';

class ImportLintPlugin extends ServerPlugin {
  ImportLintPlugin(ResourceProvider provider) : super(provider);

  var _filesFromSetPriorityFilesRequest = <String>[];

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

    late Iterable<ImportLintRule> rules;

    try {
      //debuglog(analysisContext.contextRoot.includedPaths);
      /*
			_include = analysisContext.contextRoot.includedPaths
          .map((e) => Glob(e, recursive: true, caseSensitive: false))
          .toList();
			*/
      //debuglog(_include);

      for (final i in analysisContext.contextRoot.included) {
        /*
        final test = analysisContext.contextRoot.packagesFile;
        final a = i.provider.pathContext.current;
        //i.provider.pathContext.style.

        if (io.File('${i.path}/.packages').existsSync()) {
          _include
              .add(Glob('${i.path}', recursive: true, caseSensitive: false));
          debuglog(i.path);
        }
				*/
        final packagesFile =
            io.File(i.parent.canonicalizePath('${i.shortName}/.packages'));
        final hasPackagesFile = packagesFile.existsSync();

        if (hasPackagesFile) {
          _include
              .add(Glob('${i.path}', recursive: true, caseSensitive: false));
        }
        //final packages = findPackagesFrom(i.provider, i);
        //debuglog([packages.packages.length, i.path]);
        //final package = packages.packageForPath(i.path);
        //debuglog([package?.name, i.path]);
        //debuglog([i.path, i.shortName, i.provider.pathContext.current]);
      }

      final rootDirectoryPath = context.contextRoot.root.path;
      final options = ImportLintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFilePath: optionsFile!,
      );
      registerLintRules(options);
      rules = options.rules.value.map((e) => ImportLintRule(e));

      //registerLintRules(options);
    } catch (e, s) {
      channel.sendNotification(
        plugin.PluginErrorParams(
          true,
          'Failed to load options: ${e.toString()}',
          s.toString(),
        ).toNotification(),
      );
    }

    //debuglog(context.driver);

    final lintOptions = LinterOptions(rules)
      ..enabledLints = rules
      ..resourceProvider = PhysicalResourceProvider.INSTANCE;

    final linter = DartLinter(lintOptions);

    runZonedGuarded(
      () {
        dartDriver.results.listen((analysisResult) async {
          if (analysisResult is ResolvedUnitResult) {
            final result = await _check(analysisResult, dartDriver, linter);
            //debuglog([result.length, analysisResult.path]);

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
    ResolvedUnitResult unit,
    AnalysisDriver driver,
    DartLinter linter,
  ) async {
    final included = _include.any((e) => e.matches(unit.path));

    //debuglog([included, unit.path, _include]);
    if (!included) {
      return [];
    }

    /*
    debuglog([
      excluded,
      unit.path,
      _exclude,
    ]);
		*/

    final result = await linter.lintFiles([io.File(unit.path)]);

    final List<AnalysisError> errors = [];

    for (final info in result) {
      for (final e in info.errors) {
        if (e.message.contains('Found Import Lint Error')) {
          errors.add(AnalysisError(
            AnalysisErrorSeverity('WARNING'),
            AnalysisErrorType.LINT,
            Location(
              unit.path,
              e.offset,
              e.length,
              0,
              0,
            ),
            e.message,
            'import_lint',
            correction: 'Try removing the import.',
            hasFix: false,
          ));
        }
      }
    }

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

/*
void debuglog(Object value) {
  final file = io.File(
          '/Users/ryo/Documents/packages/import_lint_test/import-lint/log.txt')
      .openSync(mode: io.FileMode.append);
  file.writeStringSync('$value\n');
}
*/
