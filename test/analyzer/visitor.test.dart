import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VisitorTest);
  });
}

@reflectiveTest
class VisitorTest with BaseResourceProviderMixin {
  VisitorTest() {
    setUp();
  }

  void test_visitor_visitChildren() async {
    newFile('/lib/target/test.dart', '''
import 'package:example/from/except.dart';
import 'package:example/from/test.dart';
''');

    final rule = Rule('example', [
      Constraint(
        ConstraintType.target,
        'example',
        Glob('target/*.dart', recursive: true, caseSensitive: false),
      ),
      Constraint(
        ConstraintType.from,
        'example',
        Glob('from/*.dart', recursive: true, caseSensitive: false),
      ),
      Constraint(
        ConstraintType.except,
        'example',
        Glob('from/except.dart', recursive: true, caseSensitive: false),
      )
    ]);

    final path = '/lib/target/test.dart';
    final context = buildContext();
    final result = await context.currentSession.getResolvedUnit(path)
        as ResolvedUnitResult;

    final filePathResourceLocator = FilePathResourceLocator.fromUri(
        packageName, Uri.file(result.path), Uri.directory('/'));

    ImportDirective? directive;
    result.unit.visitChildren(ImportLintVisitor(
      [rule],
      filePathResourceLocator,
      (d, rule) {
        directive = d;
      },
    ));

    expect(directive?.uri.stringValue, 'package:example/from/test.dart');
  }
}
