import 'package:import_lint/src/utils.dart';

class Import {
  const Import._({
    required this.sourceFilePath,
    required this.importedPackage,
    required String fullImportPath,
    required this.isRelativeImport,
  }) : _fullImportPath = fullImportPath;

  final String sourceFilePath;
  final String importedPackage;
  final String _fullImportPath;
  final bool isRelativeImport;

  String get importedFilePath {
    if (!isRelativeImport) {
      return _fullImportPath;
    }
    return _removePackageOfPath;
  }

  String get _removePackageOfPath =>
      _fullImportPath.replaceFirst('package:$importedPackage/', '');

  static Import? create({
    required String uriUsedToImport,
    required String fullImportPath,
    required String sourceFilePath,
  }) {
    final package = extractPackage(fullImportPath);
    if (package == null) {
      return null;
    }

    return Import._(
      sourceFilePath: sourceFilePath,
      importedPackage: package,
      isRelativeImport: extractPackage(uriUsedToImport) == null,
      importedFilePath: fullImportPath,
    );
  }
}
