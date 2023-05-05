import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DriverBasedAnalysisContextAnalyzerTest);
  });
}

@reflectiveTest
class DriverBasedAnalysisContextAnalyzerTest with BaseResourceProviderMixin {
  DriverBasedAnalysisContextAnalyzerTest() {
    setUp();
  }

  void test_analyzer_analyzeFile() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example:
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
    final path = '/lib/target/test.dart';
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final issues = (await analyzer.analyzeFile(path)).toList();
    expect(issues.length, 2);

    final firstIssue = issues[0];
    expect(firstIssue.rule.name, 'example');
    expect(firstIssue.source.path, '/lib/target/test.dart');

    final secondIssue = issues[1];
    expect(secondIssue.rule.name, 'example');
    expect(secondIssue.source.path, '/lib/target/test.dart');
  }

  void test_analyzer_analyzeFiles() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');

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
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final issues = await analyzer.analyzeFiles([
      '/lib/target/1.dart',
      '/lib/target/2.dart',
    ]);
    expect(issues.length, 4);
  }

  void test_analyzer_analyzedFiles() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');

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
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final paths = analyzer.analyzedFiles();
    expect(paths.length, 2);
  }

  void test_analyzer_handleInvalidPathResult() async {
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');
    final context = buildContext();
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    expect(
      () => analyzer.analyzeFile(
        'empty.dart',
      ),
      throwsA(isA<BaseException>()),
    );
  }
}
