// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:glob/glob.dart';
import 'package:import_lint/src/domain/import.dart';
import 'package:import_lint/src/domain/rules/rule.dart';

class ImportAllowed implements ConstraintRule {
  ImportAllowed({
    required this.forbiddenImports,
    required this.excludedImports,
  });

  List<Glob> forbiddenImports;
  List<Glob> excludedImports;

  @override
  bool isViolatedBy(Import importInfo) {
    return forbiddenImports.any(
            (forbidden) => forbidden.matches(importInfo.importedFilePath)) &&
        !excludedImports
            .any((ruleItem) => ruleItem.matches(importInfo.importedFilePath));
  }
}
