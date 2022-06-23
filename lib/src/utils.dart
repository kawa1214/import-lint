import 'dart:io';
import 'package:analyzer/file_system/physical_file_system.dart';

String toPackagePath(
  String path,
) {
  final separator = Platform.pathSeparator;
  final reg = RegExp('\\${separator}lib\\${separator}(.*)');
  final match = reg.firstMatch(path)?.group(1);

  if (match == null) {
    return path;
  } else {
    return match;
  }
}

String absoluteNormalizedPath(String path) {
  final pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  return pathContext.normalize(
    pathContext.absolute(path),
  );
}

const int $backslash = 0x5c;

const int $pipe = 0x7c;
