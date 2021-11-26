import 'package:import_lint/import_lint/import_lint_options.dart';
import 'package:import_lint/import_lint/issue/path.dart';
import 'package:path/path.dart' as p;

class Line {
  Line(this.value, this.convertedLibPath);

  factory Line.ofFromLine({
    required String lineContent,
    required ImportLintOptions options,
    required Path filePath,
  }) {
    return Line(
      lineContent,
      _convertLibPath(
        options: options,
        filePath: filePath,
        lineContent: lineContent,
      ),
    );
  }

  final String value;
  final String convertedLibPath;

  bool get isImport => value.startsWith('import');

  /// convert library path
  /// ex. /lib/xxx/xxx.dart
  static String _convertLibPath({
    required Path filePath,
    required ImportLintOptions options,
    required String lineContent,
  }) {
    late String fixedPath;

    final importContentMatch =
        RegExp('(?<=\').*?(?=\')|(?<=\").*?(?=\")').firstMatch(lineContent);

    if (importContentMatch == null) {
      return '';
    }
    fixedPath = importContentMatch.group(0) ?? '';

    fixedPath = fixedPath.replaceAll('package:${options.packageName}', '');

    if (p.isAbsolute(fixedPath)) {
      return '/lib$fixedPath';
    }

    final dir = p.dirname(filePath.value);

    final relativeToAbsolutePath = p.normalize('$dir/$fixedPath/');
    final converted =
        relativeToAbsolutePath.replaceAll(options.directoryPath, '');

    return converted;
  }

  int get removeImportOffset {
    const importValue = 'import ';
    if (value.startsWith(importValue)) {
      return importValue.length;
    }
    return 0;
  }

  int get removeSemicolonOffset {
    const semicolonValue = ';';
    if (value.endsWith(';')) {
      return semicolonValue.length;
    }
    return 0;
  }
}
