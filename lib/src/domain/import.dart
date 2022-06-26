class Import {
  const Import._({
    required this.sourceFilePath,
    required this.importedPackage,
    required this.importedFilePath,
  });

  final String sourceFilePath;
  final String importedPackage;
  final String importedFilePath;

  static Import? create({
    required String uriUsedToImport,
    required String fullImportPath,
    required String sourceFilePath,
  }) {
    final package = _packageFromFullPath(fullImportPath);
    if (package == null) {
      return null;
    }

    return Import._(
        sourceFilePath: sourceFilePath,
        importedPackage: package,
        importedFilePath: uriUsedToImport);
  }

  static String? _packageFromFullPath(String source) {
    final packageRegExpResult =
        RegExp('(?<=package:).*?(?=\/)').stringMatch(source);

    return packageRegExpResult;
  }
}
