import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:import_lint/src/infra/factory/rule-container-factory.dart';

import '../infra/analysis_options_reader.dart';

RuleContainerFactory containerFactoryFromContextRoot(ContextRoot contextRoot) {
  return RuleContainerFactory(
    AnalysisOptionsReader(optionsFile: contextRoot.optionsFile),
  );
}
