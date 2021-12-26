import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:import_lint/src/import_lint_options.dart';
import 'package:import_lint/src/paths.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:import_lint/src/import_lint_options.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;

class ImportLintAnalyze {
  const ImportLintAnalyze(this.issues);

  factory ImportLintAnalyze.ofFile({
    required io.File file,
    required CompilationUnit unit,
    required ImportLintOptions options,
  }) {
    final issues = <Issue>[];
    final directives = unit.directives;

    for (final directive in directives) {
      final importPathEntity = directive.childEntities.toList()[1];
      final importPathValue =
          importPathEntity.toString().substring(1, importPathEntity.length - 1);
      final libPath = _toLibPath(
        path: importPathValue,
        options: options,
        file: file,
      );
      final rule = _ruleCheck(file: file, libValue: libPath, options: options);

      if (rule != null) {
        final location = unit.lineInfo?.getLocation(directive.offset);

        issues.add(Issue(
          source: directive.toSource(),
          file: file,
          lineNumber: location?.lineNumber ?? 0,
          startOffset: importPathEntity.offset,
          length: importPathEntity.length,
          rule: rule,
        ));
      }
    }
    return ImportLintAnalyze(issues);
  }

  final List<Issue> issues;

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

  static Future<ImportLintAnalyze> ofInitCli(
      {required ImportLintOptions options}) async {
    final resultIssues = <Issue>[];
    final paths = Paths.ofDartFile(directoryPath: options.directoryPath);
    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollection(
      resourceProvider: resourceProvider,
      includedPaths: paths.value,
    );

    for (final context in collection.contexts) {
      final filePaths = context.contextRoot.analyzedFiles();
      for (final filePath in filePaths) {
        final result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          final analyzed = ImportLintAnalyze.ofFile(
            file: io.File(filePath),
            unit: result.unit,
            options: options,
          );
          resultIssues.addAll(analyzed.issues);
        }
      }
    }
    return ImportLintAnalyze(resultIssues);
  }

  static String _toLibPath({
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

    return '';
  }

  static Rule? _ruleCheck({
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
}

class Issue {
  Issue({
    required this.source,
    required this.file,
    required this.lineNumber,
    required this.startOffset,
    required this.length,
    required this.rule,
  });
  final String source;
  final io.File file;
  final int lineNumber;
  final int startOffset;
  final int length;
  final Rule rule;

  plugin.Location get location {
    return plugin.Location(
      file.path,
      startOffset,
      length,
      lineNumber,
      0,
    );
  }

  plugin.AnalysisError get pluginError {
    return plugin.AnalysisError(
      plugin.AnalysisErrorSeverity('WARNING'),
      plugin.AnalysisErrorType.LINT,
      location,
      'Found Import Lint Error: ${rule.name}',
      'import_lint',
      correction: 'Try removing the import.',
      hasFix: false,
    );
  }
}
