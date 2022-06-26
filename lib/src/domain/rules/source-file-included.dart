import 'package:glob/glob.dart';
import 'package:import_lint/src/domain/import.dart';
import 'package:import_lint/src/domain/rules/rule.dart';

class SourceFileIncluded implements ElegibleRule {
  SourceFileIncluded({
    required this.includedFilesPattern,
    required this.excludedFilesPattern,
  });

  Glob includedFilesPattern;
  List<Glob> excludedFilesPattern;

  @override
  bool isImportElegible(Import import) {
    return includedFilesPattern.matches(import.sourceFilePath) &&
        !excludedFilesPattern
            .any((excludedPath) => excludedPath.matches(import.sourceFilePath));
  }
}
