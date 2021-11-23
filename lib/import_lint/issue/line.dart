import 'package:import_lint/import_lint/issue/path.dart';
import 'package:path/path.dart' as p;

class Line {
  const Line(this.value);
  final String value;

  bool get isImport => value.startsWith('import');

  /// convert library path
  /// ex. /lib/xxx/xxx.dart
  String convertLibPath({
    required Path filePath,
    required String packageName,
    required String directoryPath,
  }) {
    final importPath = value
        .replaceAll(';', '')
        .replaceAll('\'', '')
        .replaceAll('\"', '')
        .replaceAll('import ', '')
        .replaceAll('package:$packageName', '');

    if (p.isAbsolute(importPath)) {
      return '/lib$importPath';
    }

    final dir = p.dirname(filePath.value);

    final relativeToAbsolutePath = p.normalize('$dir/$importPath/');
    final converted = relativeToAbsolutePath.replaceAll(directoryPath, '');

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
