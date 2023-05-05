import 'dart:isolate' show SendPort;

import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer_plugin/starter.dart' show ServerPluginStarter;

import 'plugin.dart';

void start(Iterable<String> _, SendPort sendPort) {
  ServerPluginStarter(
          ImportLintPlugin(resourceProvider: PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
