import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerTest);
  });
}

@reflectiveTest
class AnalyzerTest with BaseResourceProviderMixin {
  AnalyzerTest() {
    setUp();
  }

  void test_analyzer_analyzeFile() async {
    newFile('/lib/target/test.dart', '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    final context = buildContext();
    final path = '/lib/target/test.dart';
    final config = Config(severity: Severity.info, rules: [
      Rule('example', [
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
      ]),
    ]);
    final analyzer = Analyzer(config);

    final issues = (await analyzer.analyzeFile(context, path)).toList();
    expect(issues.length, 2);

    final firstIssue = issues[0];
    expect(firstIssue.rule.name, 'example');
    expect(firstIssue.source.path, '/lib/target/test.dart');

    final secondIssue = issues[1];
    expect(secondIssue.rule.name, 'example');
    expect(secondIssue.source.path, '/lib/target/test.dart');
  }

  void test_analyzer_analyzeFiles() async {
    newFile('/lib/target/1.dart', '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    newFile('/lib/target/2.dart', '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    final context = buildContext();
    final config = Config(severity: Severity.info, rules: [
      Rule('example', [
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
      ]),
    ]);
    final analyzer = Analyzer(config);

    final issues = await analyzer.analyzeFiles(context, [
      '/lib/target/1.dart',
      '/lib/target/2.dart',
    ]);
    expect(issues.length, 4);
  }

  void test_analyzer_handleInvalidPathResult() async {
    final context = buildContext();
    final config = Config(severity: Severity.info, rules: []);
    final analyzer = Analyzer(config);

    expect(
      () => analyzer.analyzeFile(
        context,
        'empty.dart',
      ),
      throwsA(isA<BaseException>()),
    );
  }
}
