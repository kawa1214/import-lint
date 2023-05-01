import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:import_lint/src/analyzer/issue.dart';
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

  void test_correctFormat_importSource() async {
    newFile('/lib/src/1.dart', '''
import 'dart:io';
''');
    final context = buildContext();

    final result = await context.currentSession
        .getResolvedUnit('/lib/src/1.dart') as ResolvedUnitResult;

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final importSource = ImportSource.fromImportDirective(result, directive);

    expect(importSource.path, '/lib/src/1.dart');
    expect(importSource.offset, 0);
    expect(importSource.length, 17);
    expect(importSource.startLine, 1);
    expect(importSource.endLine, 1);
    expect(importSource.startColumn, 8);
    expect(importSource.endColumn, 17);
  }
}
