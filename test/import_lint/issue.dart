import 'package:import_lint/import_lint/import_lint_options.dart';
import 'package:import_lint/import_lint/issue.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';
import 'package:analyzer/source/line_info.dart' as plugin;

import '../helper/generate_test_project.dart';

void runIssueTest() {
  group('issue', () {
    test('not found imports', () {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, 0);
    });
    test('packge imports', () {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, project.notAllowImportCount);
    });
    test('relative imports', () {
      final project = GenerateTestProject.ofRelativeImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, project.notAllowImportCount);
    });
    test('absolute imports', () {
      final project = GenerateTestProject.ofAbsoluteImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, project.notAllowImportCount);
    });
    test('library prefix imports', () {
      final project = GenerateTestProject.ofLibraryPrefixIImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, project.notAllowImportCount);
    });
    test('no issues output', () {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.output, 'No issues found! 🎉');
    });
    test('space custom imports', () {
      final project = GenerateTestProject.ofSpacePathImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.value.length, project.notAllowImportCount);
    });
    test('no issues output', () {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(issues.output, 'No issues found! 🎉');
    });
    test('has issues output', () {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);
      final issues = Issues.ofInitCli(options: options);

      expect(
        issues.output,
        '   custom_rule • package:example/test/helper/generated_project/custom/example_target.dart:4 • import \'package:example/custom/first_not_allow.dart\'; \n'
        '   custom_rule • package:example/test/helper/generated_project/custom/example_target.dart:5 • import \'package:example/custom/second_not_allow.dart\'; \n'
        '\n'
        ' 2 issues found.',
      );
    });
    test('init plugin', () {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final options =
          ImportLintOptions.init(directoryPath: project.directoryPath);

      final file = project.files.where((e) => e.path.endsWith('.dart')).first;
      final filePath = project.directoryPath + file.path;
      final lineInfo = plugin.LineInfo.fromContent(file.content);
      final contentLines = file.content.split('\n');

      final issues = Issues.ofInitPlugin(
        options: options,
        filePath: filePath,
        lineInfo: lineInfo,
        contentLines: contentLines,
      );

      final errors = issues.value.map((e) => e.pluginError).toList();

      expect(errors.length, project.notAllowImportCount);
    });
  });
}
