import 'dart:isolate';

import 'package:import_lint/plugin/plugin_starter.dart' as plugin;

void main(List<String> args, SendPort sendPort) {
  debuglog('DEBUG');
  plugin.start(args, sendPort);
}
