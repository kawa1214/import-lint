import 'package:cli_util/cli_logging.dart' show Logger;
import 'package:import_lint/src/analyzer/analyzer.dart';
import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/cli/reporter.dart';
import 'package:import_lint/src/config/severity.dart';

typedef ExitCode = int;

class Runner {
  const Runner(this._logger, this._analyzer);
  final Logger _logger;
  final Analyzer _analyzer;

  Future<ExitCode> run(Iterable<String> args) async {
    final progress = _logger.progress('Analyzing');

    final paths = _analyzer.analyzedFiles();
    final issues = await _analyzer.analyzeFiles(paths);

    final buf = StringBuffer();
    final reporter = Reporter(_analyzer.config, buf);
    reporter.writeIssues(issues);
    _logger.write(buf.toString());

    progress.finish(showTiming: true);

    final code = _exitCode(_analyzer.config.severity, issues);
    return code;
  }

  ExitCode _exitCode(Severity severity, Iterable<Issue> issues) {
    final hasError = issues.length > 0 && severity == Severity.error;
    if (hasError) {
      return 1;
    }
    return 0;
  }
}
