import 'dart:isolate';

import 'package:import_lint/src/plugin/plugin_starter.dart' as plugin;

void main(List<String> args, SendPort sendPort) {
  plugin.start(args, sendPort);
}
