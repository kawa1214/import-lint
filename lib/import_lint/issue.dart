import 'dart:io' as io;

import 'package:analyzer/source/line_info.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:import_lint/import_lint/import_lint_options.dart';
import 'package:import_lint/import_lint/issue/line.dart';
import 'package:import_lint/import_lint/issue/path.dart';

import 'import_lint_options/rule.dart';

/// In CLI, it is created in execution units, and in Plugin, it is created in file units.
class Issues {
  const Issues(this.value, this.options);

  factory Issues.ofInitCli({
    required ImportLintOptions options,
  }) {
    final paths = Paths.ofDartFile(directoryPath: options.directoryPath);

    final issues = <Issue>[];
    for (final path in paths.value) {
      final lines = io.File(path.value).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final issue = Issue(
          filePath: path,
          line: Line(line),
          lineIndex: i,
          startOffset: null,
        );
        issues.add(issue);
      }
    }
    final errorIssues = issues
        .where((e) => e.isError(
              options: options,
            ))
        .toList();
    return Issues(errorIssues, options);
  }

  factory Issues.ofInitPlugin({
    required ImportLintOptions options,
    required String filePath,
    required plugin.LineInfo lineInfo,
    required List<String> contentLines,
  }) {
    final issues = <Issue>[];

    for (var i = 0; i < contentLines.length; i++) {
      final line = contentLines[i];
      final startOffset = lineInfo.getOffsetOfLine(i);
      final issue = Issue(
        filePath: Path(filePath),
        line: Line(line),
        lineIndex: i,
        startOffset: startOffset,
      );

      issues.add(issue);
    }

    final errorIssues = issues
        .where((e) => e.isError(
              options: options,
            ))
        .toList();
    return Issues(errorIssues, options);
  }

  final List<Issue> value;
  final ImportLintOptions options;

  String get output {
    if (value.isEmpty) {
      return 'No issues found! 🎉';
    }

    final currentDic = io.Directory.current;

    final buffer = StringBuffer();

    for (final issue in value) {
      final modFilePath = issue.filePath.value
          .replaceAll(currentDic.path, '')
          .replaceAll('lib/', '');
      final modLineContent = issue.line.value.replaceAll(';', '');
      buffer.write(
        '   ${issue.rule?.name} '
        '• package:${options.packageName}$modFilePath:${issue.lineIndex + 1} '
        '• $modLineContent \n',
      );
    }

    buffer.write('\n ${value.length} issues found.');

    return buffer.toString();
  }
}

/// [startOffset] Used Only in Analyze Plugin
class Issue {
  Issue({
    required this.filePath,
    required this.line,
    required this.lineIndex,
    required this.startOffset,
  });
  final Path filePath;
  final Line line;
  final int lineIndex;
  final int? startOffset;
  late Rule? rule;

  plugin.Location get location {
    return plugin.Location(
      filePath.value,
      startOffset! + line.removeImportOffset,
      line.value.length - line.removeImportOffset - line.removeSemicolonOffset,
      lineIndex,
      0,
    );
  }

  plugin.AnalysisError get pluginError {
    return plugin.AnalysisError(
      plugin.AnalysisErrorSeverity('WARNING'),
      plugin.AnalysisErrorType.LINT,
      location,
      'Found Import Lint Error: ${rule?.name}',
      'import_lint',
      correction: 'Try removing the import.',
      hasFix: false,
    );
  }

  bool isError({
    required ImportLintOptions options,
  }) {
    for (final ruleValue in options.rules.value) {
      if (!ruleValue.targetFilePath.matches(filePath.value)) {
        continue;
      }

      for (final notAllowImportRule in ruleValue.notAllowImports) {
        if (!line.isImport) {
          return false;
        }

        if (notAllowImportRule.matches(line.convertLibPath(
          filePath: filePath,
          packageName: options.packageName,
          directoryPath: options.directoryPath,
        ))) {
          final isIgnore = ruleValue.excludeImports
              .map((e) => e.matches(line.convertLibPath(
                    filePath: filePath,
                    packageName: options.packageName,
                    directoryPath: options.directoryPath,
                  )))
              .contains(true);
          if (isIgnore) {
            continue;
          }
          rule = ruleValue;
          return true;
        }
      }
    }

    return false;
  }
}
