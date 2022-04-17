import 'package:import_lint/import_lint.dart';

String toProjectPath({
  required String path,
  required ImportLintOptions options,
}) {
  final fixedPath = path.replaceFirst('${options.common.directoryPath}', '');
  if (fixedPath.startsWith('/')) {
    return fixedPath.replaceFirst('/', '');
  }
  if (fixedPath.startsWith(r'\')) {
    return fixedPath.replaceFirst(r'\', '');
  }
  return fixedPath;
}
