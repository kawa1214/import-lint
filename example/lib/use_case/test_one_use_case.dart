import 'package:example/repository/test_two_repository.dart';
import 'package:example/use_case/base_use_case.dart';
import 'package:example/use_case/test_two_use_case.dart';

import '/use_case/test_two_use_case.dart';
import './foo_use_case.dart';

class TestOneUseCase implements BaseUseCase {}

final a = TestTwoRepository();
final b = TestTwoUseCase(TestOneUseCase());
final c = FooUseCase();
