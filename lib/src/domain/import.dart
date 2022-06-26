class Import {
  const Import._({
    required this.sourceFilePath,
    required this.importedFilePath,
  });

  final String sourceFilePath;
  final String importedFilePath;

  static Import? create({
    required String fullImportPath,
    required String sourceFilePath,
  }) {
    return Import._(
      sourceFilePath: sourceFilePath,
      importedFilePath: fullImportPath,
    );
  }
}
