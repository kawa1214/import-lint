import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';

String toPackagePath(
  String path,
) {
  final normalizedPath = _normalizePath(path);
  final reg = RegExp('\/(lib|test)\/(.*)');
  final match = reg.firstMatch(normalizedPath)?.group(2);
  final result = match ?? normalizedPath;
  return result;
}

String _normalizePath(String path) {
  final separator = Platform.pathSeparator;
  return path.replaceAll(separator, '/');
}

String absoluteNormalizedPath(String path) {
  final pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  return pathContext.normalize(
    pathContext.absolute(path),
  );
}

const int $backslash = 0x5c;

const int $pipe = 0x7c;
