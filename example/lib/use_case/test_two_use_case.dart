import 'test_one_use_case.dart';
import 'package:import_lint/import_lint.dart';

class TestTwoUseCase {
  const TestTwoUseCase(this.testOneUseCase);
  final TestOneUseCase testOneUseCase;
}
