import 'package:analyzer/dart/element/element.dart' show DirectiveUri;
import 'package:analyzer/src/dart/element/element.dart'
    show DirectiveUriWithLibraryImpl, DirectiveUriWithRelativeUriImpl;
import 'package:import_lint/src/exceptions/argument_exception.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';

class ImportLineResourceLocator implements ResourceLocator {
  const ImportLineResourceLocator({
    required this.package,
    required this.path,
  });

  factory ImportLineResourceLocator.fromUri(
    DirectiveUri? uri,
    FilePathResourceLocator filePath,
  ) {
    if (uri is DirectiveUriWithLibraryImpl) {
      // uri is import '../../import_lint.dart';
      final relativeUri = uri.relativeUriString;
      if (relativeUri.startsWith('dart:')) {
        final reg = RegExp('(?<=dart:).*');
        final path = reg.firstMatch(relativeUri)?.group(0);
        if (path == null) {
          throw InternalException('path is null');
        }
        return ImportLineResourceLocator(package: 'dart', path: path);
      }

      final fullUri = uri.source.fullName;
      final path = RegExp('lib\/(.*)').firstMatch(fullUri)?.group(1);
      if (path == null) {
        throw InternalException('path is null');
      }

      return ImportLineResourceLocator(package: filePath.package, path: path);
    } else if (uri is DirectiveUriWithRelativeUriImpl) {
      // uri is import 'package:import_lint/import_lint.dart';
      final relativeUri = uri.relativeUriString;

      final package = RegExp('(?<=package:).*?(?=\/)').stringMatch(relativeUri);
      if (package == null) {
        throw InternalException('package is null');
      }

      final path = relativeUri.replaceFirst('package:$package/', '');

      return ImportLineResourceLocator(package: package, path: path);
    }

    throw InternalException('Unsupported ImportDirective');
  }

  final String package;
  final String path;
}

class FilePathResourceLocator implements ResourceLocator {
  const FilePathResourceLocator({
    required this.package,
    required this.path,
  });

  factory FilePathResourceLocator.fromFilePath(
    String package,
    String filePath,
    String rootPath,
  ) {
    final relativePath = filePath.replaceFirst(rootPath, '');

    final reg = RegExp('lib\/(.*)');
    final path = reg.firstMatch(relativePath)?.group(1);
    if (path == null) {
      throw ArgumentException('lib path is required');
    }

    return FilePathResourceLocator(
      package: package,
      path: path,
    );
  }

  final String package;
  final String path;
}

abstract class ResourceLocator {
  // coverage:ignore-start
  const ResourceLocator({
    required this.package,
    required this.path,
  });
  // coverage:ignore-end

  final String package;
  final String path;
}
