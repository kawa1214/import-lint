import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FilePathResourceLocatorTest);
    defineReflectiveTests(ImportLineResourceLocatorTest);
  });
}

@reflectiveTest
class FilePathResourceLocatorTest {
  static const _packageName = 'example';

  void test_resourceLocator_checkCorrectFormat() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.directory('/users/project/');

    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      _packageName,
      fileUri,
      directoryUri,
    );

    expect(filePathResourceLocator.package, _packageName);
    expect(filePathResourceLocator.path, 'src/1.dart');
  }

  void test_resourceLocator_handleInvalidFileUri() async {
    final fileUri = Uri.http('example.com');
    final directoryUri = Uri.directory('/users/project/');

    expect(
      () => FilePathResourceLocator.fromUri(
        _packageName,
        fileUri,
        directoryUri,
      ),
      throwsA(isA<BaseException>()),
    );
  }

  void test_resourceLocator_handleInvalidDirectoryUri() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.http('example.com');

    expect(
      () => FilePathResourceLocator.fromUri(
        _packageName,
        fileUri,
        directoryUri,
      ),
      throwsA(isA<BaseException>()),
    );
  }

  void test_resourceLocator_handleInvalidFileUriPath() async {
    final fileUri = Uri.file('/users/project/src/1.dart');
    final directoryUri = Uri.directory('/users/project/');

    expect(
      () => FilePathResourceLocator.fromUri(
        _packageName,
        fileUri,
        directoryUri,
      ),
      throwsA(isA<BaseException>()),
    );
  }
}

@reflectiveTest
class ImportLineResourceLocatorTest {
  static const _packageName = 'example';

  void test_resourceLocator_handlePackageUri() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.directory('/users/project');
    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      _packageName,
      fileUri,
      directoryUri,
    );

    final importUri = Uri.parse('package:example/src/2.dart');
    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      importUri,
      filePathResourceLocator,
    );

    expect(importLineResourceLocator.package, _packageName);
    expect(importLineResourceLocator.path, 'src/2.dart');
  }

  void test_resourceLocator_handleDartUri() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.directory('/users/project');
    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      _packageName,
      fileUri,
      directoryUri,
    );

    final importUri = Uri.parse('dart:io');
    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      importUri,
      filePathResourceLocator,
    );

    expect(importLineResourceLocator.package, 'dart');
    expect(importLineResourceLocator.path, 'io');
  }

  void test_resourceLocator_handleRelativeUri() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.directory('/users/project');
    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      _packageName,
      fileUri,
      directoryUri,
    );

    final importUri = Uri.parse('../2.dart');
    final importLineResourceLocator = ImportLineResourceLocator.fromUri(
      importUri,
      filePathResourceLocator,
    );

    expect(importLineResourceLocator.package, _packageName);
    expect(importLineResourceLocator.path, '2.dart');
  }

  void test_resourceLocator_handleInvalidUri() async {
    final fileUri = Uri.file('/users/project/lib/src/1.dart');
    final directoryUri = Uri.directory('/users/project/');

    final filePathResourceLocator = FilePathResourceLocator.fromUri(
      _packageName,
      fileUri,
      directoryUri,
    );

    final importUri = Uri.http('example.com');

    expect(
      () => ImportLineResourceLocator.fromUri(
        importUri,
        filePathResourceLocator,
      ),
      throwsA(isA<BaseException>()),
    );

    expect(filePathResourceLocator.package, _packageName);
    expect(filePathResourceLocator.path, 'src/1.dart');
  }
}
