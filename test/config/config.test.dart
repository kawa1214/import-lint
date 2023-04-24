import 'package:import_lint/src/config/analysis_options.dart';
import 'package:import_lint/src/config/config.dart';
import 'package:import_lint/src/config/severity.dart';
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
  static const _rootKey = 'import_lint';
  static const _rulesKey = 'rules';
  static const _severity = {'severity': 'error'};
  static const _rules = {
    '${_rulesKey}': {
      'example': {
        'target': 'package:example/target/*_target.dart',
        'from': 'package:example/from/*.dart',
        'expect': [
          'package:example/target/expect.dart',
        ]
      }
    }
  };

  void test_correctFormat() {
    final map = {
      _rootKey: {
        ..._severity,
        ..._rules,
      }
    };
    final config = Config.fromAnalysisOptions(AnalysisOptions(map));

    expect(config.severity, Severity.error);
    expect(config.rules.length, _rules[_rulesKey]?.length);
  }

  void test_nullRootKey() {
    final map = {
      ..._severity,
      ..._rules,
    };

    expect(
      () => Config.fromAnalysisOptions(AnalysisOptions(map)),
      throwsA(isA<BaseException>()),
    );
  }

  void test_nullRulesKey() {
    final map = {
      _rootKey: {
        ..._severity,
      }
    };

    expect(
      () => Config.fromAnalysisOptions(AnalysisOptions(map)),
      throwsA(isA<BaseException>()),
    );
  }
}
