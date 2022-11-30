import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:import_lint/src/infra/error_collector.dart';

import 'create_container_factory.dart';

ErrorCollector createCollector(DriverBasedAnalysisContext context) {
  return ErrorCollector(
      containerFactoryFromContextRoot(context.contextRoot), context);
}
