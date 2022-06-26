import 'package:import_lint/src/domain/import.dart';

abstract class ConstraintRule {
  bool isViolatedBy(Import importInfo);
}

abstract class ElegibleRule {
  bool isImportElegible(Import import);
}
