import 'package:glob/glob.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstrainthTest);
  });
}

@reflectiveTest
class ConstrainthTest {
  static const _package = 'example';
  static const _pattern = 'target/*.dart';

  void test_target() {
    final target = Constraint.fromString(
      ConstraintType.target,
      'package:${_package}/${_pattern}',
    );

    expect(target.package, _package);
    expect(
      target.glob.pattern,
      Glob(_pattern, recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_from() {
    final target = Constraint.fromString(
      ConstraintType.from,
      'package:${_package}/${_pattern}',
    );

    expect(target.package, _package);
    expect(
      target.glob.pattern,
      Glob(_pattern, recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_except() {
    final target = Constraint.fromString(
      ConstraintType.except,
      'package:${_package}/${_pattern}',
    );

    expect(target.package, _package);
    expect(
      target.glob.pattern,
      Glob(_pattern, recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_null() {
    expect(
      () => Constraint.fromString(ConstraintType.target, null),
      throwsA(isA<BaseException>()),
    );
  }

  void test_empty() {
    expect(
      () => Constraint.fromString(ConstraintType.target, ''),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalidPackage() {
    expect(
      () => Constraint.fromString(
          ConstraintType.target, 'error:${_package}/${_pattern}'),
      throwsA(isA<BaseException>()),
    );
  }
}
