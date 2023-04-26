import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:import_lint/src/analyzer/path.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../helper/base_resource_provider_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathTest);
  });
}

@reflectiveTest
class PathTest with BaseResourceProviderMixin {
  PathTest() {
    setUp();
  }

  void test_correctFormat() async {
    newFile('/lib/target/test.dart', '''
void main() {
}
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final path = FilePath.fromResolvedUnitResult(context, result);

    expect(path.package, packageName);
    expect(path.path, 'target/test.dart');
  }
}
