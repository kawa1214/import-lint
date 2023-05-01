import 'analyzer/analyzer.test.dart' as analyzer;
import 'analyzer/constraint_resolver.test.dart' as constraint_resolver;
import 'analyzer/issue.test.dart' as issue;
import 'analyzer/resource_locator.test.dart' as resource_locator;
import 'analyzer/visitor.test.dart' as visitor;
import 'cli/reporter.test.dart' as reporter;
import 'config/analysis_options.test.dart' as analysis_options;
import 'config/config.test.dart' as config;
import 'config/constraint.test.dart' as constraint;
import 'config/rule.test.dart' as rule;
import 'config/severity.test.dart' as severity;
import 'exceptions/base_exception.test.dart' as exception;

export 'helper/coverage_test.dart';

void main() {
  // exception
  exception.main();

  // config
  analysis_options.main();
  severity.main();
  constraint.main();
  rule.main();
  config.main();

  // analyzer
  resource_locator.main();
  constraint_resolver.main();
  visitor.main();
  issue.main();
  analyzer.main();

  // cli
  reporter.main();
}
