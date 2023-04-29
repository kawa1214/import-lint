import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResourceLocator);
  });
}

@reflectiveTest
class ResourceLocator with BaseResourceProviderMixin {
  PathTest() {
    setUp();
  }

  void test_filePath() async {
    newFile('/lib/target/test.dart', '''
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePathResourceLocator =
        FilePathResourceLocator.fromResolvedUnitResult(context, result);

    expect(filePathResourceLocator.package, packageName);
    expect(filePathResourceLocator.path, 'target/test.dart');
  }

  void test_relativeUriImportLine() async {
    newFile('/lib/target/test.dart', '''
import 'package:example/from/test.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePathResourceLocator =
        FilePathResourceLocator.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final importLineResourceLocator =
        ImportLineResourceLocator.fromImportDirective(
            directive, filePathResourceLocator);

    expect(importLineResourceLocator.package, packageName);
    expect(importLineResourceLocator.path, 'from/test.dart');
  }

  void test_directiveUriImportLine() async {
    newFile('/lib/target/test.dart', '''
import '../from/test.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePathResourceLocator =
        FilePathResourceLocator.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final importLineResourceLocator =
        ImportLineResourceLocator.fromImportDirective(
            directive, filePathResourceLocator);

    expect(importLineResourceLocator.package, packageName);
    expect(importLineResourceLocator.path, 'from/test.dart');
  }

  void test_anotherPackageSourcePath() async {
    newFile('/lib/target/test.dart', '''
import 'package:$anotherPackageName/src/example.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePathResourceLocator =
        FilePathResourceLocator.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final importLineResourceLocator =
        ImportLineResourceLocator.fromImportDirective(
            directive, filePathResourceLocator);

    expect(importLineResourceLocator.package, anotherPackageName);
    expect(importLineResourceLocator.path, 'src/example.dart');
  }
}
