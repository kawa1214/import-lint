import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:yaml/yaml.dart' show YamlMap, YamlList, loadYamlNode;

/// Parse analysis_options.yaml file.
class AnalysisOptions {
  const AnalysisOptions(this.options);

  factory AnalysisOptions.fromYaml(File file) {
    final value = file.readAsStringSync();

    final node = loadYamlNode(value);

    late YamlMap yaml;
    if (node is YamlMap) {
      yaml = node;
    } else {
      yaml = YamlMap();
    }

    final map = _readMap(yaml);

    return AnalysisOptions(map);
  }

  /// Read a map from a YamlMap.
  /// This function is called recursively to read nested maps.
  static Map<String, Object> _readMap(YamlMap yaml) {
    final result = <String, Object>{};
    for (final key in yaml.nodes.keys) {
      final node = yaml[key];
      final value = _readNode(node);
      if (value != null) {
        result[key.value as String] = value;
      }
    }
    return Map.unmodifiable(result);
  }

  /// Read a value from a YamlNode.
  static Object? _readNode(dynamic node) {
    if (node is YamlMap) {
      return _readMap(node);
    } else if (node is YamlList) {
      final listOfStrings = node.toList().whereType<String>();
      return List<String>.unmodifiable(listOfStrings);
    } else if (node is String) {
      return node;
    } else {
      return null;
    }
  }

  final Map<String, Object> options;
}
