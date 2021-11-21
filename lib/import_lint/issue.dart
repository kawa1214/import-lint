import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;

import 'rule.dart';

/// [startOffset] Used Only in Analyze Plugin
class Issue {
  Issue({
    required this.filePath,
    required this.lineContent,
    required this.lineIndex,
    required this.startOffset,
  });
  final String filePath;
  final String lineContent;
  final int lineIndex;
  final int? startOffset;
  late Rule? rule;

  plugin.Location get toLocation {
    return plugin.Location(
      filePath,
      startOffset!,
      lineContent.length,
      lineIndex,
      0,
    );
  }

  plugin.AnalysisError get toPluginError {
    return plugin.AnalysisError(
      plugin.AnalysisErrorSeverity('WARNING'),
      plugin.AnalysisErrorType.LINT,
      toLocation,
      'Found Import Lint Error: ${rule?.name}',
      'import_lint',
      correction: 'Try removing the import.',
      hasFix: true,
    );
  }

  bool isError({required Rules rules}) {
    for (final ruleValue in rules.value) {
      if (!ruleValue.searchFilePathRegExp.hasMatch(filePath)) {
        continue;
      }

      for (final notAllowImportRule in ruleValue.notAllowImportRegExps) {
        if (notAllowImportRule.hasMatch(lineContent)) {
          final isIgnore = ruleValue.excludeImportRegExps
              .map((e) => e.hasMatch(lineContent))
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
