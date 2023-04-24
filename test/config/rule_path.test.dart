import 'package:glob/glob.dart';
import 'package:import_lint/src/config/rule_path.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RulePathTest);
  });
}

@reflectiveTest
class RulePathTest {
  static const _package = 'example';
  static const _pattern = 'target/*_target.dart';

  void test_correctFormat() {
    final rulePath = RulePath.fromString('package:${_package}/${_pattern}');

    expect(rulePath.package, _package);
    expect(
      rulePath.pattern.pattern,
      Glob(_pattern, recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_null() {
    expect(
      () => RulePath.fromString(null),
      throwsA(isA<BaseException>()),
    );
  }

  void test_empty() {
    expect(
      () => RulePath.fromString(''),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalid_package() {
    expect(
      () => RulePath.fromString('error:${_package}/${_pattern}'),
      throwsA(isA<BaseException>()),
    );
  }
}
