import 'package:import_lint/import_lint.dart';
import 'package:test/test.dart';

import '../helper/generate_test_project.dart';

void runImportLintAnalyzeTest() {
  group('import lint analyze', () {
    test('not found imports', () async {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });
    test('packge imports', () async {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });

    test('relative imports', () async {
      final project = GenerateTestProject.ofRelativeImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });
    test('absolute imports', () async {
      final project = GenerateTestProject.ofAbsoluteImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });
    test('library prefix imports', () async {
      final project = GenerateTestProject.ofLibraryPrefixImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });
    test('space custom imports', () async {
      final project = GenerateTestProject.ofSpacePathImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
    });
    test('no issues output', () async {
      final project = GenerateTestProject.ofImportLintOptions();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
      expect(analyzed.output, 'No issues found! 🎉');
    });
    test('has issues output', () async {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);
      expect(
        analyzed.output,
        '   warning • test/helper/generated_project/lib/custom/example_target.dart:4:8 • import \'package:example/custom/first_not_allow.dart\'; • custom_rule\n'
        '   warning • test/helper/generated_project/lib/custom/example_target.dart:5:8 • import \'package:example/custom/second_not_allow.dart\'; • custom_rule\n'
        '\n'
        ' 2 issues found.',
      );
    });
    test('init plugin', () async {
      final project = GenerateTestProject.ofPackageImportDartFiles();
      project.generate();

      final analyzed = await ImportLintAnalyze.ofInitCli(
        rootDirectoryPath: project.directoryPath,
      );

      expect(analyzed.issues.length, project.notAllowImportCount);

      final errors = analyzed.issues.map((e) => e.pluginError).toList();

      expect(errors.length, project.notAllowImportCount);
    });
  });
}
