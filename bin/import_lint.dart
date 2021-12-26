import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:import_lint/src/import_lint_analyze.dart';
import 'package:import_lint/src/import_lint_options.dart';
import 'package:import_lint/src/import_lint_options/rule.dart';
import 'package:import_lint/src/issue.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  try {
    final rootDirectoryPath = io.Directory.current.path;
    final options = ImportLintOptions.init(directoryPath: rootDirectoryPath);
    final analyzed = await ImportLintAnalyze.ofInitCli(options: options);
    print(analyzed.issues.map((e) => e.pluginError).length);
    /*
    final paths = Paths.ofDartFile(directoryPath: options.directoryPath);
    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollection(
        resourceProvider: resourceProvider,
        includedPaths: paths.value.map((e) => e.value).toList());
    for (final context in collection.contexts) {
      final paths = context.contextRoot.analyzedFiles();
      for (final path in paths) {
        final result = await context.currentSession.getResolvedUnit(path);
        if (result is ResolvedUnitResult) {
          final issues = Issues.ofFile(
            file: io.File(path),
            unit: result.unit,
            options: options,
          );
          print(issues);
        }
      }
    }
    */
    //final issues = ImportLint.ofInitCli(options: options);

    //io.stdout.writeln(issues.output);
    io.exit(0);
  } catch (e, s) {
    io.stdout.writeln('${e.toString()}\n');
    io.stdout.writeln(s);
    io.exit(1);
  }
}

String _toLibPath({
  required String path,
  required io.File file,
  required ImportLintOptions options,
}) {
  if (p.isAbsolute(path)) {
    return 'lib$path';
  }

  if (p.isRelative(path)) {
    if (path.startsWith('package:')) {
      return 'lib/${path.replaceFirst(RegExp('package.*?\/'), '')}';
    }

    final normalized = p
        .normalize('${file.parent.path}/$path')
        .replaceFirst('${options.directoryPath}/', '');

    return normalized;
  }
  throw Exception('convert import');
}

Rule? _ruleCheck({
  required io.File file,
  required String libValue,
  required ImportLintOptions options,
}) {
  for (final ruleValue in options.rules.value) {
    if (!ruleValue.targetFilePath.matches(file.path)) {
      continue;
    }

    for (final notAllowImportRule in ruleValue.notAllowImports) {
      if (notAllowImportRule.matches(libValue)) {
        final isIgnore = ruleValue.excludeImports
            .map((e) => e.matches(libValue))
            .contains(true);
        if (isIgnore) {
          continue;
        }
        return ruleValue;
      }
    }
  }

  return null;
}
