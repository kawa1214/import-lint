import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:import_lint/src/application/import_lint_visitor.dart';
import 'package:import_lint/src/infra/factory/rule-container-factory.dart';

class ErrorCollector {
  ErrorCollector(this.containerFactory, this.context);

  final RuleContainerFactory containerFactory;
  final DriverBasedAnalysisContext context;

  Future<List<AnalysisError>> collectErrorsFor(String path) async {
    final result = await context.currentSession.getResolvedUnit(path)
        as ResolvedUnitResult;

    final workspace = context.contextRoot.workspace;
    final package = workspace.findPackageFor(path);

    if (package is! PubWorkspacePackage) return [];

    final packageName = package.pubspec?.name?.value.text;

    if (packageName == null) return [];

    final errors = <AnalysisError>[];

    for (final container in containerFactory.create()) {
      result.unit.visitChildren(ImportLintVisitor(
        container,
        result.path,
        packageName,
        result.unit,
        (error) {
          errors.add(error);
        },
      ));
    }

    return errors;
  }
}
