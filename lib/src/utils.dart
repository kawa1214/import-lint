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
