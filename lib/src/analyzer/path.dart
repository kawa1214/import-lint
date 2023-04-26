import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;
import 'package:import_lint/src/exceptions/argument_exception.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';

class SourcePath extends Path {
  const SourcePath({
    required this.package,
    required this.path,
  }) : super(package: package, path: path);

  final String package;
  final String path;
}

class FilePath extends Path {
  const FilePath({
    required this.package,
    required this.path,
  }) : super(package: package, path: path);

  factory FilePath.fromResolvedUnitResult(
    DriverBasedAnalysisContext context,
    ResolvedUnitResult result,
  ) {
    final workspacePackage =
        context.contextRoot.workspace.findPackageFor(result.path);
    if (workspacePackage is! PubWorkspacePackage) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }
    final package = workspacePackage.pubspec?.name?.value.text;
    if (package == null) {
      throw InternalException('workspacePackage is not PubWorkspacePackage');
    }

    final reg = RegExp('\/lib\/(.*)');
    final path = reg.firstMatch(result.path)?.group(1);
    if (path == null) {
      throw ArgumentException('lib path is required');
    }

    return FilePath(
      package: package,
      path: path,
    );
  }

  final String package;
  final String path;
}

abstract class Path {
  const Path({required this.package, required this.path});
  final String package;
  final String path;
}
