import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';

import 'plugin.dart';

void start(Iterable<String> _, SendPort sendPort) {
  ServerPluginStarter(
          ImportLintPlugin(resourceProvider: PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
