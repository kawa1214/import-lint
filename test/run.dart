@Tags(['presubmit-only'])
import 'package:import_lint/src/cli.dart';
import 'package:test/test.dart';

export 'helper/coverage_test.dart';

void main() {
  test('packge imports', () async {
    final v = logger.isVerbose;

    expect(v, false);
  });

  //runImportLintOptionsTest();
  //runImportLintAnalyzeTest();
  //runIssueTest();
}
