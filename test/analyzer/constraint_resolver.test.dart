import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/resource_locator.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstraintResolverTest);
  });
}

@reflectiveTest
class ConstraintResolverTest {
  void test_violated() async {
    final constraints = [
      TargetConstraint(
        'example',
        Glob('target/*.dart', recursive: true, caseSensitive: false),
      ),
      FromConstraint(
        'example',
        Glob('from/*.dart', recursive: true, caseSensitive: false),
      ),
      ExceptConstraint(
        'example',
        Glob('from/except.dart', recursive: true, caseSensitive: false),
      )
    ];

    final filePathResourceLocator =
        FilePathResourceLocator(package: 'example', path: 'target/test.dart');
    final importLineResourceLocator =
        ImportLineResourceLocator(package: 'example', path: 'from/test.dart');

    final resolver = ConstraintResolver(constraints);

    final isViolated =
        resolver.isViolated(filePathResourceLocator, importLineResourceLocator);
    expect(isViolated, true);
  }

  void test_except() async {
    final constraints = [
      TargetConstraint(
        'example',
        Glob('target/*.dart', recursive: true, caseSensitive: false),
      ),
      FromConstraint(
        'example',
        Glob('from/*.dart', recursive: true, caseSensitive: false),
      ),
      ExceptConstraint(
        'example',
        Glob('from/except.dart', recursive: true, caseSensitive: false),
      )
    ];

    final filePathResourceLocator =
        FilePathResourceLocator(package: 'example', path: 'target/test.dart');
    final importLineResourceLocator =
        ImportLineResourceLocator(package: 'example', path: 'from/except.dart');

    final resolver = ConstraintResolver(constraints);

    final isViolated =
        resolver.isViolated(filePathResourceLocator, importLineResourceLocator);
    expect(isViolated, false);
  }
}
