import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/cli/reporter.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/config/severity.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReporterTest);
  });
}

@reflectiveTest
class ReporterTest {
  void test_writeIssues() async {
    final config = Config(
      severity: Severity.error,
      rules: [],
    );

    final buf = StringBuffer();
    final reporter = Reporter(config, buf);

    final issues = [
      Issue(
        Rule('example_rule', []),
        ImportSource(
          path: 'example.dart',
          length: 4,
          offset: 5,
          startLine: 1,
          endLine: 2,
          startColumn: 3,
          endColumn: 0,
        ),
      ),
    ];

    reporter.writeIssues(issues);
    expect(
      '   error • example.dart:1:3 • example_rule\n\n1 issues found.',
      buf.toString(),
    );
  }

  void test_writeIssues_empty() async {
    final config = Config(
      severity: Severity.error,
      rules: [],
    );

    final buf = StringBuffer();
    final reporter = Reporter(config, buf);

    final issues = <Issue>[];

    reporter.writeIssues(issues);
    expect('No issues found! 🎉\n', buf.toString());
  }

  void test_writeIssues_escape() async {
    final config = Config(
      severity: Severity.error,
      rules: [],
    );

    final buf = StringBuffer();
    final reporter = Reporter(config, buf);

    final issues = [
      Issue(
        Rule('\\example_rule', []),
        ImportSource(
          path: 'example.dart',
          length: 4,
          offset: 5,
          startLine: 1,
          endLine: 2,
          startColumn: 3,
          endColumn: 0,
        ),
      ),
    ];
    reporter.writeIssues(issues);
    expect(
      '   error • example.dart:1:3 • \\\\example_rule\n\n1 issues found.',
      buf.toString(),
    );
  }
}
