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

      final pathSource = importDirective.selectedSource?.fullName;
      if (pathSource == null) {
        continue;
      }

      final libPath = toProjectPath(
        path: pathSource,
        options: options,
      );

      /*
      print(['selectedUriContent', importDirective.selectedUriContent]);
      print(['libPath', libPath]);
      */

      final importContent = importDirective.selectedUriContent;

      if (importContent == null) {
        break;
      }

      final rules = _ruleCheck(
          file: file,
          importContent: importContent,
          libPath: libPath,
          options: options);

      final location = unit.lineInfo?.getLocation(directive.offset);

      final result = rules
          .map((e) => ImportLintError(
                source: directive.toSource(),
                file: io.File(filePath),
                lineNumber: location?.lineNumber ?? 0,
                startOffset: pathEntity.offset,
                length: pathEntity.length,
                rule: e,
              ))
          .toList();

      issues.addAll(result);
    }

    return ImportLintAnalyze(issues);
  }

  final List<ImportLintError> issues;

  static List<Rule> _ruleCheck({
    required io.File file,
    required String importContent,
    required String libPath,
    required ImportLintOptions options,
  }) {
    final result = <Rule>[];
    for (final ruleValue in options.rules.value) {
      //print([ruleValue.targetFilePath, file.path]);
      if (!ruleValue.targetFilePath.matches(file.path)) {
        continue;
      }

      // package:example/use_case/test_one_use_case.dart
      late String package;
      late String importValue;

      final packageRegExpResult =
          RegExp('(?<=package:).*?(?=\/)').stringMatch(importContent);
      if (packageRegExpResult != null) {
        package = packageRegExpResult;
      } else {
        package = options.common.packageName;
      }

      if (package == options.common.packageName) {
        importValue = libPath;
      } else {
        importValue = importContent.replaceFirst('package:$package/', '');
      }

      for (final notAllowImportRule in ruleValue.notAllowImports) {
        print(['file', file.path, importValue, package]);
        print([
          'notAllowImportRule',
          notAllowImportRule.package,
          notAllowImportRule.path
        ]);
        print(['match', notAllowImportRule.path.matches(importValue)]);
        if (notAllowImportRule.path.matches(importValue)) {
          final isIgnore = ruleValue.excludeImports
              .map((e) => e.path.matches(importValue))
              .contains(true);
          if (isIgnore) {
            continue;
          }
          result.add(ruleValue);
        }
      }
    }

    return result;
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
