@Tags(['presubmit-only'])
import 'package:test/test.dart';

import 'lint_options.test.dart' as lint_options;
import 'rule.test.dart' as rule;

export 'helper/coverage_test.dart';

void main() {
  lint_options.main();
  rule.main();
}
