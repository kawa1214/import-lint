import 'package:import_lint/import_lint/issue.dart';
import 'package:import_lint/import_lint/rule.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'dart:io' as io;

const path = 'analysis_options.yaml';

void main(List<String> arguments) async {
  try {
    final packageName = await _packageName();
    final rules = Rules.fromParsedYaml(path);
    final paths = await _dartFilePaths();
    final issues = _checkIssue(paths: paths, rules: rules);
    final output = _output(issues: issues, packageName: packageName);
    io.stdout.writeln(output);
    io.exit(0);
  } catch (e) {
    io.stdout.writeln('😿' + e.toString().replaceAll('Exception: ', ''));
    io.exit(1);
  }
}

Future<String> _packageName() async {
  final pubspecFile = io.File("pubspec.yaml");
  final value = await pubspecFile.readAsString();
  final loadYaml = yaml.loadYaml(value);
  return loadYaml['name'];
}

Future<List<String>> _dartFilePaths() async {
  final dic = io.Directory.current;
  final dartFileRegExp = RegExp('.*\.dart\$');
  final result = <String>[];
  await for (final entry in dic.list(recursive: true, followLinks: false)) {
    if (dartFileRegExp.hasMatch(entry.path)) {
      result.add(entry.path);
    }
  }
  return result;
}

List<Issue> _checkIssue({
  required Rules rules,
  required List<String> paths,
}) {
  final issues = <Issue>[];
  for (final path in paths) {
    final lines = io.File(path).readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final issue = Issue(
        filePath: path,
        lineContent: line,
        lineIndex: i,
        startOffset: null,
      );
      issues.add(issue);
    }
  }
  final modIssues = issues.where((e) => e.isError(rules: rules)).toList();
  return modIssues;
}

String _output({
  required String packageName,
  required List<Issue> issues,
}) {
  if (issues.isEmpty) {
    return 'No issues found! 🎉';
  }

  final currentDic = io.Directory.current;

  final buffer = StringBuffer();

  for (final issue in issues) {
    final modFilePath =
        issue.filePath.replaceAll(currentDic.path, '').replaceAll('lib/', '');
    final modLineContent = issue.lineContent.replaceAll(';', '');
    buffer.write(
      '   ${issue.rule!.name} • package:$packageName$modFilePath:${issue.lineIndex} • $modLineContent \n',
    );
  }

  buffer.write('\n ${issues.length} issues found.');

  return buffer.toString();
}
