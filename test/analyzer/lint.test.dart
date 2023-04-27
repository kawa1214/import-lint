import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer_plugin/protocol/protocol_common.dart' show Location;
import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/lint.dart';
import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/rule_path.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LintTest);
  });
}

@reflectiveTest
class LintTest with BaseResourceProviderMixin {
  LintTest() {
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

    Location? location;
    result.unit.visitChildren(ImportLintVisitor(
      rule,
      filePath,
      (directive) {
        final lineInfo = result.unit.lineInfo;
        final loc = lineInfo.getLocation(directive.uri.offset);
        final locEnd = lineInfo.getLocation(directive.uri.end);
        location = Location(
          path,
          directive.offset,
          directive.length,
          loc.lineNumber,
          loc.columnNumber,
          endLine: locEnd.lineNumber,
          endColumn: locEnd.columnNumber,
        );
      },
    ));

    expect(location?.file, path);

    expect(location?.offset, 43);
    expect(location?.length, 40);

    expect(location?.startLine, 2);
    expect(location?.endLine, 2);

    expect(location?.startColumn, 8);
    expect(location?.endColumn, 40);
  }
}
