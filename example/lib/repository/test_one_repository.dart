import 'package:example/repository/sub/one/test_one_sub.dart';
import 'package:example/repository/sub/two/test_two_sub.dart';
import 'package:example/repository/test_two_repository.dart';
import 'package:example/space test/test.dart' as space;

import '/repository/test_two_repository.dart';
import './test_two_repository.dart';
import '../use_case/base_use_case.dart' as test;

class TestOneRepository extends test.BaseUseCase {}

final a = space.SpaceTest();
final b = TestTwoRepository();
final c = TestOnSub();
final d = TestTwoSub();
