// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:import_lint/src/domain/import.dart';
import 'package:import_lint/src/domain/import_constraint.dart';
import 'package:import_lint/src/domain/rules/rule.dart';

class ImportAllowed implements ConstraintRule {
  ImportAllowed({
    required this.forbiddenImports,
    required this.excludedImports,
  });

  List<ImportConstraint> forbiddenImports;
  List<ImportConstraint> excludedImports;

  @override
  bool isViolatedBy(Import importInfo) {
    return forbiddenImports
            .any((forbidden) => forbidden.isViolatedBy(importInfo)) &&
        !excludedImports.any((ruleItem) => ruleItem.isViolatedBy(importInfo));
  }
}
