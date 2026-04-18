import 'package:analyzer/file_system/file_system.dart' show File;
import 'package:import_lint/src/exceptions/argument_exception.dart';
import 'package:yaml/yaml.dart' show YamlMap, YamlList, loadYamlNode;

/// Provides a wrapper around the `analysis_options.yaml` file for easier access to its contents.
class AnalysisOptions {
  /// Wraps an already-parsed map of `analysis_options.yaml` entries.
  ///
  /// Prefer [AnalysisOptions.fromFile] for the common case where you
  /// have a file on disk; this constructor exists so tests (and other
  /// callers that have a parsed map in hand) can build an instance
  /// without round-tripping through YAML.
  const AnalysisOptions(this.options);

  /// Reads, parses, and returns the contents of the supplied
  /// `analysis_options.yaml` [file].
  ///
  /// Throws [ArgumentException] if [file] is `null` (the analyzer
  /// passes `null` when no options file is found).
  factory AnalysisOptions.fromFile(File? file) {
    if (file == null) {
      throw ArgumentException('must be a File');
    }

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

  /// Parsed `analysis_options.yaml` contents, keyed by top-level
  /// section name. The value of each entry is either a `String`, a
  /// `List<String>`, or a recursively-parsed `Map<String, Object>`.
  /// The map is unmodifiable.
  final Map<String, Object> options;
}
