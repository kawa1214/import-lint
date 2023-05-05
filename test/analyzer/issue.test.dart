import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show AnalysisErrorType, AnalysisErrorSeverity;
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IssueTest);
  });
}

@reflectiveTest
class IssueTest with BaseResourceProviderMixin {
  PathTest() {
    setUp();
  }

  void test_issue_checkCorrectFormatOfImportSource() async {
    newFile('/lib/src/1.dart', '''
import 'dart:io';
''');
    final context = buildContext();

    final result = await context.currentSession
        .getResolvedUnit('/lib/src/1.dart') as ResolvedUnitResult;

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;
    final lineInfo = LineInfo.fromContent('import \'dart:io\';');
    final importSource = ImportSource.fromImportDirective(lineInfo, directive);

    expect(importSource.offset, 0);
    expect(importSource.length, 17);
    expect(importSource.startLine, 1);
    expect(importSource.endLine, 1);
    expect(importSource.startColumn, 8);
    expect(importSource.endColumn, 17);
  }

  void test_issue_convertToAnalysisError() async {
    final importSource = ImportSource(
      content: 'dart:io',
      offset: 0,
      length: 17,
      startLine: 1,
      endLine: 1,
      startColumn: 8,
      endColumn: 17,
    );
    final rule = Rule('example', []);
    final issue = Issue('/lib/src/1.dart', rule, importSource);

    final analysisError = issue.analysisError(Severity.error);

    expect(analysisError.severity, AnalysisErrorSeverity.ERROR);
    expect(analysisError.type, AnalysisErrorType.LINT);
    expect(analysisError.location.file, '/lib/src/1.dart');
    expect(analysisError.location.offset, 0);
    expect(analysisError.location.length, 17);
    expect(analysisError.location.startLine, 1);
    expect(analysisError.location.startColumn, 8);
    expect(analysisError.location.endLine, 1);
    expect(analysisError.location.endColumn, 17);
    expect(analysisError.message, 'Found Import Lint Error: example');
    expect(analysisError.code, 'import_lint');
    expect(analysisError.correction, 'Try removing the import.');
    expect(analysisError.hasFix, false);
  }
}
