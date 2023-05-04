import 'package:collection/collection.dart';
import 'package:import_lint/src/exceptions/argument_exception.dart';

class ImportLineResourceLocator implements ResourceLocator {
  const ImportLineResourceLocator({
    required this.package,
    required this.path,
  });

  factory ImportLineResourceLocator.fromUri(
    Uri uri,
    FilePathResourceLocator filePathResourceLocator,
  ) {
    if (uri.scheme == 'dart') {
      final pathSegments = uri.pathSegments.skip(0);
      final path = pathSegments.join('/');
      return ImportLineResourceLocator(package: 'dart', path: path);
    }

    if (uri.scheme == 'package') {
      final package = uri.pathSegments.first;
      final pathSegments = uri.pathSegments.skip(1);
      final path = pathSegments.join('/');
      return ImportLineResourceLocator(package: package, path: path);
    }

    if (!uri.isAbsolute) {
      final relativeUri = filePathResourceLocator.relativeUri.resolveUri(uri);
      final pathSegments = relativeUri.pathSegments.skip(1);
      final path = pathSegments.join('/');

      return ImportLineResourceLocator(
        package: filePathResourceLocator.package,
        path: path,
      );
    }

    throw ArgumentException('Unsupported uri');
  }

  final String package;
  final String path;
}

class FilePathResourceLocator implements ResourceLocator {
  const FilePathResourceLocator({
    required this.package,
    required this.path,
  });

  factory FilePathResourceLocator.fromUri(
    String package,
    Uri fileUri,
    Uri directoryUri,
  ) {
    if (fileUri.scheme != 'file') {
      throw ArgumentException('Input URI must have "file" scheme');
    }
    if (directoryUri.scheme != 'file') {
      throw ArgumentException('Input URI must have "file" scheme');
    }

    final filePathSegments = fileUri.pathSegments;

    final matchingPrefixLength =
        IterableZip([filePathSegments, directoryUri.pathSegments])
            .takeWhile((pair) => pair.first == pair.last)
            .length;
    final relativePathSegments = filePathSegments.skip(matchingPrefixLength);

    final reg = RegExp('lib\/(.*)');
    final relativePath =
        reg.firstMatch(relativePathSegments.join('/'))?.group(1);
    if (relativePath == null) {
      throw ArgumentException('lib path is required');
    }

    return FilePathResourceLocator(
      package: package,
      path: relativePath,
    );
  }

  Uri get relativeUri {
    return Uri.parse('package:$package/${path}');
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
