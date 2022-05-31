import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:import_lint/import_lint.dart';

String toProjectPath({
  required String path,
  required ImportLintOptions options,
}) {
  final fixedPath = path.replaceFirst('${options.common.directoryPath}', '');
  if (fixedPath.startsWith('/lib/')) {
    return fixedPath.replaceFirst('/lib/', '');
  }
  if (fixedPath.startsWith(r'\lib\')) {
    return fixedPath.replaceFirst(r'\lib\', '');
  }
  return fixedPath;
}

String toPackagePath(
  String path,
  String directoryPath,
) {
  final fixedPath = path.replaceFirst('${directoryPath}', '');
  if (fixedPath.startsWith('/lib/')) {
    return fixedPath.replaceFirst('/lib/', '');
  }
  if (fixedPath.startsWith(r'\lib\')) {
    return fixedPath.replaceFirst(r'\lib\', '');
  }
  return fixedPath;
}

String absoluteNormalizedPath(String path) {
  final pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  return pathContext.normalize(
    pathContext.absolute(path),
  );
}

const int $backslash = 0x5c;

const int $pipe = 0x7c;
