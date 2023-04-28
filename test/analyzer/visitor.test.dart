import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/analyzer/visitor.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/rule_path.dart';
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

  void test_correctFormat() async {
    newFile('/lib/from/except.dart', '''
class ExceptFrom {}
''');

    newFile('/lib/from/test.dart', '''
class TestFrom {}
''');

    newFile('/lib/target/test.dart', '''
import 'package:example/from/except.dart';
import 'package:example/from/test.dart';
''');

    final rule = Rule(
      name: 'example',
      target: RulePath(
        'example',
        Glob('target/*.dart', recursive: true, caseSensitive: false),
      ),
      from: RulePath(
        'example',
        Glob('from/*.dart', recursive: true, caseSensitive: false),
      ),
      except: [
        RulePath(
          'example',
          Glob('from/except.dart', recursive: true, caseSensitive: false),
        )
      ],
    );

    final path = '/lib/target/test.dart';
    final context = buildContext();
    final result = await context.currentSession.getResolvedUnit(path)
        as ResolvedUnitResult;

    final filePath = FilePath.fromResolvedUnitResult(context, result);

    ImportDirective? directive;
    result.unit.visitChildren(ImportLintVisitor(
      rule,
      filePath,
      (d) {
        directive = d;
      },
    ));

    expect(directive?.uri.stringValue, 'package:example/from/test.dart');
  }
}
