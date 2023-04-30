import 'package:cli_util/cli_logging.dart';
import 'package:import_lint/src/cli/runner.dart';

void main(List<String> args) async {
  final logger = Logger.standard();
  final runner = Runner(logger);
  runner.run(args);
}
