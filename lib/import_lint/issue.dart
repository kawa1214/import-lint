import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:import_lint/constants/options_file_path.dart';
import 'package:import_lint/constants/package_name.dart';
import 'package:import_lint/import_lint/issue/line.dart';
import 'package:import_lint/import_lint/issue/path.dart';

import 'dart:io' as io;
import 'rule.dart';

class Issues {
  const Issues(this.value);
  final List<Issue> value;

  /// Used Only in CLI
  factory Issues.ofInitCli({required String directoryPath}) {
    final paths = Paths.ofDartFile(directoryPath: directoryPath);
    final rules =
        Rules.fromOptionsFile(optionsFilePath(directoryPath: directoryPath));

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
              rules: rules,
              directoryPath: directoryPath,
            ))
        .toList();
    return Issues(errorIssues);
  }

  String output({
    required String packageName,
    required String directoryPath,
  }) {
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
        '   ${issue.rule?.name} • package:${packageName}$modFilePath:${issue.lineIndex} • $modLineContent \n',
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
      plugin.AnalysisErrorSeverity('INFO'),
      plugin.AnalysisErrorType.LINT,
      location,
      'Found Import Lint Error: ${rule?.name}',
      'import_lint',
      correction: 'Try removing the import.',
      hasFix: true,
    );
  }

  bool isError({
    required Rules rules,
    required String directoryPath,
  }) {
    for (final ruleValue in rules.value) {
      if (!ruleValue.searchFilePath.matches(filePath.value)) {
        continue;
      }

      for (final notAllowImportRule in ruleValue.notAllowImports) {
        if (!line.isImport) {
          return false;
        }

        if (notAllowImportRule.matches(line.convertLibPath(
          filePath: filePath,
          packageName: packageNameFromPath(directoryPath),
          directoryPath: directoryPath,
        ))) {
          final isIgnore = ruleValue.excludeImports
              .map((e) => e.matches(line.convertLibPath(
                    filePath: filePath,
                    packageName: packageNameFromPath(directoryPath),
                    directoryPath: directoryPath,
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
