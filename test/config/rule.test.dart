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

  static const _expect = {
    'expect': [
      'package:example/target/expect.dart',
    ]
  };

  void test_correctFormat() {
    final map = {
      _name: {
        ..._target,
        ..._from,
        ..._expect,
      }
    };
    final rule = Rule.fromMap(_name, map[_name]);

    expect(rule.name, _name);

    expect(rule.target.package, 'example');
    expect(
      rule.target.pattern.pattern,
      Glob('target/*_target.dart', recursive: true, caseSensitive: false)
          .pattern,
    );

    expect(rule.from.package, 'example');
    expect(
      rule.from.pattern.pattern,
      Glob('from/*.dart', recursive: true, caseSensitive: false).pattern,
    );

    expect(rule.expect.length, _expect.length);
    final firstExpect = rule.expect[0];
    expect(firstExpect.package, 'example');
    expect(
      firstExpect.pattern.pattern,
      Glob('target/expect.dart', recursive: true, caseSensitive: false).pattern,
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
        ..._expect,
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
        ..._expect,
      }
    };
    expect(
      () => Rule.fromMap(_name, map[_name]),
      throwsA(isA<BaseException>()),
    );
  }

  void test_invalidExpect() {
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
