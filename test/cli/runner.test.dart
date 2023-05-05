import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/cli/runner.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/test_logger.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RunnerTest);
  });
}

@reflectiveTest
class RunnerTest {
  void test_runner_run() async {
    final buf = StringBuffer();
    final logger = TestLogger(buf);

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
      ),
    ]);
    final analyzer = _FakeAnalyzer(
      [
        Issue(
          rule,
          ImportSource(
            content: '',
            path: '',
            offset: 0,
            length: 0,
            startLine: 0,
            endLine: 0,
            startColumn: 0,
            endColumn: 0,
          ),
        ),
      ],
      Config(severity: Severity.warning, rules: [rule]),
    );
    final runner = Runner(logger, analyzer);

    final code = await runner.run([]);
    expect(code, 0);
    expect(buf.toString().contains('1 issues found.'), true);
  }

  void test_runnner_severityError() async {
    final buf = StringBuffer();
    final logger = TestLogger(buf);
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
      ),
    ]);
    final analyzer = _FakeAnalyzer(
      [
        Issue(
          rule,
          ImportSource(
            content: '',
            path: '',
            offset: 0,
            length: 0,
            startLine: 0,
            endLine: 0,
            startColumn: 0,
            endColumn: 0,
          ),
        ),
      ],
      Config(severity: Severity.error, rules: [rule]),
    );

    final runner = Runner(logger, analyzer);
    final code = await runner.run([]);

    expect(code, 1);
    expect(buf.toString().contains('1 issues found.'), true);
  }
}

class _FakeAnalyzer implements Analyzer {
  const _FakeAnalyzer(this._issues, this._config);
  final Iterable<Issue> _issues;
  final Config _config;

  @override
  Future<Iterable<Issue>> analyzeFile(String path) {
    return Future.value(_issues);
  }

  @override
  Future<Iterable<Issue>> analyzeFiles(Iterable<String> paths) {
    return Future.value(_issues);
  }

  @override
  Iterable<String> analyzedFiles() {
    return ['/src/target/test.dart'];
  }

  @override
  Config get config => _config;
}
