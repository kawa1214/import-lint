import 'package:import_lint/src/cli/runner.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';
import '../helper/test_logger.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RunnerTest);
  });
}

@reflectiveTest
class RunnerTest with BaseResourceProviderMixin {
  RunnerTest() {
    setUp();
  }

  void test_runner_run() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: exception
  rules:
    example_rule:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');

    newFile('/lib/target/test.dart', '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    final context = buildContext();

    final buf = StringBuffer();
    final logger = TestLogger(buf);
    final runner = Runner(logger, context);

    final code = await runner.run([]);
    expect(code, 0);
    expect(buf.toString().contains('2 issues found.'), true);
  }

  void test_runnner_severityError() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example_rule:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');

    newFile('/lib/target/test.dart', '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    final context = buildContext();

    final buf = StringBuffer();
    final logger = TestLogger(buf);
    final runner = Runner(logger, context);

    final code = await runner.run([]);
    expect(code, 1);
    expect(buf.toString().contains('2 issues found.'), true);
  }

  void test_runner_errorOccurred() async {
    final context = buildContext();

    final buf = StringBuffer();
    final logger = TestLogger(buf);
    final runner = Runner(logger, context);
    final code = await runner.run([]);
    expect(code, 1);
    expect(buf.toString().contains('An error occurred while linting'), true);
  }
}
