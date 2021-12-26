import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:import_lint/src/import_lint_options.dart';
import 'package:import_lint/src/issue.dart';
import 'package:import_lint/src/paths.dart';

class ImportLintAnalyze {
  const ImportLintAnalyze(this.issues);

  final List<Issue> issues;

  static Future<ImportLintAnalyze> ofInitCli(
      {required ImportLintOptions options}) async {
    final resultIssues = <Issue>[];
    final paths = Paths.ofDartFile(directoryPath: options.directoryPath);
    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollection(
        resourceProvider: resourceProvider,
        includedPaths: paths.value.map((e) => e.value).toList());
    for (final context in collection.contexts) {
      final filePaths = context.contextRoot.analyzedFiles();
      for (final filePath in filePaths) {
        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          final issues = Issues.ofFile(
            file: io.File(filePath),
            unit: result.unit,
            options: options,
          );
          resultIssues.addAll(issues.value);
        }
      }
    }
    return ImportLintAnalyze(resultIssues);
  }

  String get output {
    if (issues.isEmpty) {
      return 'No issues found! 🎉';
    }

    final currentDic = io.Directory.current;

    final buffer = StringBuffer();

    for (final issue in issues) {
      final modFilePath =
          issue.location.file.replaceAll('${currentDic.path}/', '');

      buffer.write(
        '   warning'
        ' • $modFilePath:${issue.lineNumber}:${'import '.length + 1}'
        ' • ${issue.source}'
        ' • ${issue.rule.name}'
        '\n',
      );
    }

    buffer.write('\n ${issues.length} issues found.');

    return buffer.toString();
  }
}
