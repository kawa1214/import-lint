@Tags(['presubmit-only'])
import 'package:test/test.dart';

import 'import_lint/import_lint_analyze.dart';
import 'import_lint/import_lint_options.dart';

export 'helper/coverage_test.dart';

void main() {
  runImportLintOptionsTest();
  runImportLintAnalyzeTest();
  //runIssueTest();
}
