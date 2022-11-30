import 'package:glob/glob.dart';
import 'package:import_lint/src/domain/import.dart';

import '../utils.dart';

class ImportConstraint {
  final String? _importedPackage;
  final Glob _constraintPath;

  ImportConstraint._({
    required Glob constraintPath,
    String? importedPackage,
  })  : _importedPackage = importedPackage,
        _constraintPath = constraintPath;

  factory ImportConstraint.create(String pattern) {
    return ImportConstraint._(
      constraintPath: Glob(pattern, recursive: true, caseSensitive: false),
      importedPackage: extractPackage(pattern),
    );
  }

  bool isViolatedBy(Import import) =>
      _constraintPath.matches(import.importedFilePath) &&
      (_importedPackage == null || _importedPackage == import.importedPackage);
}
