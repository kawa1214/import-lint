import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart'
    show DirectiveUriWithLibraryImpl, DirectiveUriWithRelativeUriImpl;
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FilePathResourceLocatorTest);
    defineReflectiveTests(ImportLineResourceLocatorTest);
  });
}

@reflectiveTest
class FilePathResourceLocatorTest {
  static const _packageName = 'example';

  void test_correctFormat() async {
    final filePathResourceLocator = FilePathResourceLocator.fromFilePath(
        _packageName, '/Project/lib/src/1.dart', '/Project');

    expect(filePathResourceLocator.package, _packageName);
    expect(filePathResourceLocator.path, 'src/1.dart');
  }

  void test_invalidPath() async {
    expect(
      () => FilePathResourceLocator.fromFilePath(
          'example', 'invalid/path.dart', ''),
      throwsA(isA<BaseException>()),
    );
  }
}

@reflectiveTest
class ImportLineResourceLocatorTest with BaseResourceProviderMixin {
  PathTest() {
    setUp();
  }

  static const _packageName = 'example';

  void test_correctFormat_directiveUriWithRelativeUriImpl() async {
    final filePathResourceLocator = FilePathResourceLocator.fromFilePath(
      _packageName,
      '/lib/src/1.dart',
      '',
    );

    final uri = DirectiveUriWithRelativeUriImpl(
      relativeUri: Uri.dataFromString('package:example/src/2.dart'),
      relativeUriString: 'package:example/src/2.dart',
    );

    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      uri,
      filePathResourceLocator,
    );

    expect(importLineResourceLocator.package, _packageName);
    expect(importLineResourceLocator.path, 'src/2.dart');
  }

  void test_invalidPackage_directiveUriWithRelativeUriImpl() async {
    final filePathResourceLocator = FilePathResourceLocator.fromFilePath(
      _packageName,
      '/lib/src/1.dart',
      '',
    );

    final uri = DirectiveUriWithRelativeUriImpl(
      relativeUri: Uri.dataFromString('invalid:example/src/2.dart'),
      relativeUriString: 'invalid:example/src/2.dart',
    );

    expect(
      () => ImportLineResourceLocator.fromUri(
        uri,
        filePathResourceLocator,
      ),
      throwsA(isA<BaseException>()),
    );
  }

  void test_correctFormat_directiveUriWithLibraryImpl() async {
    newFile('/lib/src/1.dart', '''
import '../src/1.dart';
''');
    final filePathResourceLocator = FilePathResourceLocator.fromFilePath(
      _packageName,
      '/lib/src/2.dart',
      '',
    );

    final context = buildContext();

    final result = await context.currentSession
        .getResolvedUnit('/lib/src/1.dart') as ResolvedUnitResult;

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;
    final uri = directive.element?.uri as DirectiveUriWithLibraryImpl;
    final importLineResourceLocator =
        ImportLineResourceLocator.fromUri(uri, filePathResourceLocator);

    expect(importLineResourceLocator.package, _packageName);
    expect(importLineResourceLocator.path, 'src/1.dart');
  }

  void test_sdk_directiveUriWithLibraryImpl() async {
    newFile('/lib/src/1.dart', '''
import 'dart:io';
''');
    final filePathResourceLocator = FilePathResourceLocator.fromFilePath(
      _packageName,
      '/lib/src/2.dart',
      '',
    );

    final context = buildContext();

    final result = await context.currentSession
        .getResolvedUnit('/lib/src/1.dart') as ResolvedUnitResult;

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;
    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      directive.element?.uri,
      filePathResourceLocator,
    );

    expect(importLineResourceLocator.package, 'dart');
    expect(importLineResourceLocator.path, 'io');
  }
}
