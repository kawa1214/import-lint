import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:import_lint/src/import_lint_options.dart';
import 'package:import_lint/src/utils.dart';

class ImportLintAnalyze {
  const ImportLintAnalyze(this.issues);

  factory ImportLintAnalyze.ofFile({
    required String filePath,
    required io.File file,
    required CompilationUnit unit,
    required ImportLintOptions options,
  }) {
    final issues = <ImportLintError>[];
    final directives = unit.directives;

    for (final directive in directives) {
      //print(directive);
      if (directive is! ImportDirectiveImpl) {
        continue;
      }

      final importDirective = directive;

      if (importDirective.selectedSource == null) {
        continue;
      }

      if (!importDirective.selectedSource!.exists()) {
        continue;
      }

      final childEntities = directive.childEntities.toList();
      if (childEntities.length < 3) {
        continue;
      }

      final pathEntity = childEntities[1];

      //print([importEntity, pathEntity, endEntity]);
      final pathSource = importDirective.selectedSource!.fullName;

      //print(importPathValue);
      final libPath = toProjectPath(
        path: pathSource,
        options: options,
      );
      //print(['libPath', libPath]);

      final rule = _ruleCheck(file: file, libValue: libPath, options: options);

      if (rule != null) {
        final location = unit.lineInfo?.getLocation(directive.offset);

        issues.add(ImportLintError(
          source: directive.toSource(),
          file: io.File(filePath),
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

  static Rule? _ruleCheck({
    required io.File file,
    required String libValue,
    required ImportLintOptions options,
  }) {
    for (final ruleValue in options.rules.value) {
      print([ruleValue.targetFilePath, file.path]);

      if (!ruleValue.targetFilePath.matches(file.path)) {
        continue;
      }
      print('ok');

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
