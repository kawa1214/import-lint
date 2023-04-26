import 'package:glob/glob.dart';
import 'package:import_lint/src/config/rule.dart';
import 'package:import_lint/src/exceptions/base_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuleTest);
  });
}

@reflectiveTest
class RuleTest {
  static const _name = 'example';

  static const _target = {
    'target': 'package:example/target/*_target.dart',
  };

  static const _from = {
    'from': 'package:example/from/*.dart',
  };

  static const _except = {
    'except': [
      'package:example/target/except.dart',
    ]
  };

  void test_correctFormat() {
    final map = {
      _name: {
        ..._target,
        ..._from,
        ..._except,
      }
    };
    final rule = Rule.fromMap(_name, map[_name]);

    expect(rule.name, _name);

    expect(rule.target.package, 'example');
    expect(
      rule.target.path.pattern,
      Glob('target/*_target.dart', recursive: true, caseSensitive: false)
          .pattern,
    );

    expect(rule.from.package, 'example');
    expect(
      rule.from.path.pattern,
      Glob('from/*.dart', recursive: true, caseSensitive: false).pattern,
    );

    expect(rule.except.length, _except.length);
    final except = rule.except[0];
    expect(except.package, 'example');
    expect(
      except.path.pattern,
      Glob('target/except.dart', recursive: true, caseSensitive: false).pattern,
    );
  }

  void test_emptyName() {
    expect(
      () => Rule.fromMap('', {}),
      throwsA(isA<BaseException>()),
    );
  }

  void test_nullName() {
    expect(
      () => Rule.fromMap(null, {}),
      throwsA(isA<BaseException>()),
    );
  }

  void test_nullMap() {
    expect(
      () => Rule.fromMap(_name, null),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalidTarget() {
    final map = {
      _name: {
        ..._from,
        ..._except,
      }
    };
    expect(
      () => Rule.fromMap(_name, map[_name]),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalidFrom() {
    final map = {
      _name: {
        ..._target,
        ..._except,
      }
    };
    expect(
      () => Rule.fromMap(_name, map[_name]),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalidExcept() {
    final map = {
      _name: {
        ..._target,
        ..._from,
      }
    };
    expect(
      () => Rule.fromMap(_name, map[_name]),
      throwsA(isA<BaseException>()),
    );
  }
}
