import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:import_lint/src/import_lint_options.dart';
import 'package:import_lint/src/paths.dart';
import 'package:path/path.dart' as p;

class ImportLintAnalyze {
  const ImportLintAnalyze(this.issues);

  factory ImportLintAnalyze.ofFile({
    required io.File file,
    required CompilationUnit unit,
    required ImportLintOptions options,
  }) {
    final issues = <ImportLintError>[];
    final directives = unit.directives;

    for (final directive in directives) {
      //print(directive);
      final childEntities = directive.childEntities.toList();

      if (childEntities.length < 3) {
        continue;
      }

      final importEntity = childEntities[0];
      final pathEntity = childEntities[1];
      final endEntity = childEntities.last;

      if (importEntity is! KeywordToken ||
          importEntity.toString() != 'import') {
        continue;
      }

      if (pathEntity is! StringLiteral || pathEntity.toSource().length < 2) {
        continue;
      }

      if (endEntity is! SimpleToken || endEntity.toString() != ';') {
        continue;
      }

      print([importEntity, pathEntity, endEntity]);
      final pathSource = pathEntity.toSource();
      final fixedPathSource = pathSource.substring(1, pathSource.length - 1);

      //print(importPathValue);
      final libPath = _toLibPath(
        path: fixedPathSource,
        options: options,
        file: file,
      );
      final rule = _ruleCheck(file: file, libValue: libPath, options: options);

      if (rule != null) {
        final location = unit.lineInfo?.getLocation(directive.offset);

        issues.add(ImportLintError(
          source: directive.toSource(),
          file: file,
          lineNumber: location?.lineNumber ?? 0,
          startOffset: pathEntity.offset,
          length: pathEntity.length,
          rule: rule,
        ));
      }
    }
    return ImportLintAnalyze(issues);
  }

  final List<ImportLintError> issues;

  static Future<ImportLintAnalyze> ofInitCli({
    required String rootDirectoryPath,
  }) async {
    final resultIssues = <ImportLintError>[];
    final paths = Paths.ofDartFile(directoryPath: rootDirectoryPath);
    final resourceProvider = PhysicalResourceProvider.INSTANCE;

    final collection = AnalysisContextCollection(
      resourceProvider: resourceProvider,
      includedPaths: paths.value,
    );

    late ImportLintOptions options;

    for (final context in collection.contexts) {
      options = ImportLintOptions.init(
        directoryPath: rootDirectoryPath,
        optionsFilePath: context.contextRoot.optionsFile!.path,
      );

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
          .replaceFirst('${options.common.directoryPath}/', '');

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

class Output {
  const Output(this.errors);
  final List<ImportLintError> errors;

  String get output {
    if (errors.isEmpty) {
      return 'No issues found! 🎉';
    }

    final currentDic = io.Directory.current;

    final buffer = StringBuffer();

    for (final issue in errors) {
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

    buffer.write('\n ${errors.length} issues found.');

    return buffer.toString();
  }
}

class ImportLintError {
  ImportLintError({
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
