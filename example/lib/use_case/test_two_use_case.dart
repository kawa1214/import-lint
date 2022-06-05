// ignore: depend_on_referenced_packages
import 'package:import_lint/import_lint.dart';

import 'test_one_use_case.dart';

class TestTwoUseCase {
  const TestTwoUseCase(this.testOneUseCase);
  final TestOneUseCase testOneUseCase;
}

final a = ImportRulePath;
