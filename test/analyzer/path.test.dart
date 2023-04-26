import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
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

  void test_filePath() async {
    newFile('/lib/target/test.dart', '''
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final path = FilePath.fromResolvedUnitResult(context, result);

    expect(path.package, packageName);
    expect(path.path, 'target/test.dart');
  }

  void test_relativeUriSourcePath() async {
    newFile('/lib/target/test.dart', '''
import 'package:example/from/test.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePath = FilePath.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final sourcePath = SourcePath.fromImportDirective(directive, filePath);

    expect(sourcePath.package, packageName);
    expect(sourcePath.path, 'from/test.dart');
  }

  void test_directiveUriSourcePath() async {
    newFile('/lib/target/test.dart', '''
import '../from/test.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePath = FilePath.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final sourcePath = SourcePath.fromImportDirective(directive, filePath);

    expect(sourcePath.package, packageName);
    expect(sourcePath.path, 'from/test.dart');
  }

  void test_anotherPackageSourcePath() async {
    newFile('/lib/target/test.dart', '''
import 'package:$anotherPackageName/src/example.dart';
''');

    final context = buildContext();
    final result = await context.currentSession
        .getResolvedUnit('/lib/target/test.dart') as ResolvedUnitResult;

    final filePath = FilePath.fromResolvedUnitResult(context, result);

    final directives = result.unit.directives;
    final directive = directives[0] as ImportDirective;

    final sourcePath = SourcePath.fromImportDirective(directive, filePath);

    expect(sourcePath.package, anotherPackageName);
    expect(sourcePath.path, 'src/example.dart');
  }
}
