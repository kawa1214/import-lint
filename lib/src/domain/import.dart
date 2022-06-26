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
    required String fullImportPath,
    required String sourceFilePath,
  }) {
    final package = _packageFromFullPath(fullImportPath);
    if (package == null) {
      return null;
    }

    final path = _pathFromFullPath(fullImportPath, package);
    return Import._(
        sourceFilePath: sourceFilePath,
        importedPackage: package,
        importedFilePath: path);
  }

  static String? _packageFromFullPath(String source) {
    final packageRegExpResult =
        RegExp('(?<=package:).*?(?=\/)').stringMatch(source);

    return packageRegExpResult;
  }

  static String _pathFromFullPath(String source, String package) {
    return source.replaceFirst('package:$package/', '');
  }
}
