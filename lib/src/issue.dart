import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:import_lint/src/import_lint_options.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;

class Issues {
  const Issues(this.value);

  factory Issues.ofFile({
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
    return Issues(issues);
  }

  final List<Issue> value;

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
