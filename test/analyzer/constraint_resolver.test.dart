import 'package:glob/glob.dart';
import 'package:import_lint/src/analyzer/constraint_resolver.dart';
import 'package:import_lint/src/analyzer/path.dart';
import 'package:import_lint/src/config/constraint.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstraintResolverTest);
  });
}

@reflectiveTest
class ConstraintResolverTest with BaseResourceProviderMixin {
  VisitorTest() {
    setUp();
  }

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

    final filePath = FilePath(package: 'example', path: 'target/test.dart');
    final importPath = SourcePath(package: 'example', path: 'from/test.dart');

    final resolver = ConstraintResolver(constraints);

    final isViolated = resolver.isViolated(filePath, importPath);
    expect(isViolated, true);
  }
}
