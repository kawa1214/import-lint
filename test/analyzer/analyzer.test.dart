import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DriverBasedAnalysisContextAnalyzerTest);
    defineReflectiveTests(AnalyzerRuleTest);
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
    expect(firstIssue.path, '/lib/target/test.dart');

    final secondIssue = issues[1];
    expect(secondIssue.rule.name, 'example');
    expect(secondIssue.path, '/lib/target/test.dart');
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

@reflectiveTest
class AnalyzerRuleTest with BaseResourceProviderMixin {
  VisitorTest() {
    setUp();
  }

  void test_integration_rule() async {
    final path = '/lib/target/test.dart';
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    example:
      target: "package:${packageName}/target/*.dart"
      from: "package:${packageName}/from/*.dart"
      except: ["package:${packageName}/from/except.dart"]
''');

    newFile(path, '''
import 'package:${packageName}/from/test.dart';
import 'package:${packageName}/from/except.dart';
import '../from/test.dart';
''');

    final context = buildContext();
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final issues = (await analyzer.analyzeFile(path)).toList();

    expect(issues.length, 2);

    final firstIssue = issues[0];
    expect(firstIssue.source.content, 'package:${packageName}/from/test.dart');

    final secondIssue = issues[1];
    expect(secondIssue.source.content, '../from/test.dart');
  }

  void test_integration_selfRule() async {
    final path = '/lib/self/1.dart';
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    self_rule:
      target: "package:${packageName}/self/*.dart"
      from: "package:${packageName}/self/*.dart"
      except: []
''');

    newFile(path, '''
import 'package:${packageName}/self/2.dart';
import '2.dart';
''');

    final context = buildContext();
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final issues = (await analyzer.analyzeFile(path)).toList();

    expect(issues.length, 2);

    final firstIssue = issues[0];
    expect(firstIssue.source.content, 'package:${packageName}/self/2.dart');

    final secondIssue = issues[1];
    expect(secondIssue.source.content, '2.dart');
  }

  void test_integration_onlyRule() async {
    final path1 = '/lib/only/1.dart';
    final path2 = '/lib/not/1.dart';
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    only_rule:
      target: "package:${packageName}/*[!only]/*.dart"
      from: "package:${packageName}/only_from/*.dart"
      except: []
''');

    newFile(path1, '''
import 'package:${packageName}/only_from/1.dart';
''');

    newFile(path2, '''
import 'package:${packageName}/only_from/1.dart';
''');

    final context = buildContext();
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final path1Issues = (await analyzer.analyzeFile(path1)).toList();

    expect(path1Issues.length, 0);

    final path2Issues = (await analyzer.analyzeFile(path2)).toList();

    expect(path2Issues.length, 1);
    expect(path2Issues[0].source.content,
        'package:${packageName}/only_from/1.dart');
  }

  void test_integration_packageRule() async {
    final path = '/lib/target/test.dart';
    newFile('/analysis_options.yaml', '''
import_lint:
  severity: error
  rules:
    package_rule:
      target: "package:${packageName}/**/*.dart"
      from: "package:${anotherPackageName}/*.dart"
      except: []
''');

    newFile(path, '''
import 'package:${anotherPackageName}/1.dart';
''');

    final context = buildContext();
    final analyzer = DriverBasedAnalysisContextAnalyzer(context);

    final issues = (await analyzer.analyzeFile(path)).toList();

    expect(issues.length, 1);

    final firstIssue = issues[0];
    expect(
      firstIssue.source.content,
      'package:${anotherPackageName}/1.dart',
    );
  }
}
