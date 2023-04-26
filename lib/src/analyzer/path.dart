import 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show ImportDirective;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart'
    show DriverBasedAnalysisContext;
import 'package:analyzer/src/dart/element/element.dart'
    show DirectiveUriWithLibraryImpl, DirectiveUriWithRelativeUriImpl;
import 'package:analyzer/src/workspace/pub.dart' show PubWorkspacePackage;
import 'package:import_lint/src/exceptions/argument_exception.dart';
import 'package:import_lint/src/exceptions/internal_exception.dart';

class SourcePath implements Path {
  const SourcePath({
    required this.package,
    required this.path,
  });

  factory SourcePath.fromImportDirective(
    ImportDirective directive,
    FilePath filePath,
  ) {
    final uri = directive.element?.uri;

    if (uri is DirectiveUriWithLibraryImpl) {
      // uri is import '../../import_lint.dart';
      final fullUri = uri.source.fullName;
      final path = RegExp('\/lib\/(.*)').firstMatch(fullUri)?.group(1);
      if (path == null) {
        throw InternalException('path is null');
      }

      return SourcePath(package: filePath.package, path: path);
    } else if (uri is DirectiveUriWithRelativeUriImpl) {
      // uri is import 'package:import_lint/import_lint.dart';
      final relativeUri = uri.relativeUriString;

      final package = RegExp('(?<=package:).*?(?=\/)').stringMatch(relativeUri);
      if (package == null) {
        throw InternalException('package is null');
      }

      final path = relativeUri.replaceFirst('package:$package/', '');

      return SourcePath(package: package, path: path);
    }

    throw InternalException('uri is not DirectiveUriWithLibraryImpl');
  }

  final String package;
  final String path;
}

class FilePath implements Path {
  const FilePath({
    required this.package,
    required this.path,
  });

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
