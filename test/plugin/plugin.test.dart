import 'package:import_lint/src/plugin/plugin.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLintPluginTest);
  });
}

@reflectiveTest
class ImportLintPluginTest {
  void test_importLintPlugin_nameMatchesLintName() {
    final plugin = ImportLintPlugin();

    expect(plugin.name, 'import_lint');
  }
}
