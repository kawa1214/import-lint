@Tags(['presubmit-only'])
import 'package:test/test.dart';

import 'import_lint/import_lint_analyze.dart';
import 'import_lint/import_lint_options.dart';
import 'import_lint/paths.dart';

export 'helper/coverage_test.dart';

void main() {
  runImportLintOptionsTest();
  runPathsTest();
  runImportLintAnalyzeTest();
  //runIssueTest();
}
