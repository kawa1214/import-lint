import 'package:import_lint/src/analyzer/issue.dart';
import 'package:import_lint/src/config/config.dart';

class Reporter {
  const Reporter(this.config, this.out);
  final Config config;
  final StringBuffer out;

  void writeIssues(Iterable<Issue> issues) {
    if (issues.isEmpty) {
      out.writeln('No issues found! 🎉');
      return;
    }

    issues.forEach((e) => _writeLint(e));

    out
      ..writeln('')
      ..write('${issues.length} issues found.');
  }

  void _writeLint(Issue issue) {
    final source = issue.source;
    out
      ..write('   ')
      ..write(_escapePipe(config.severity.name))
      ..write(' • ')
      ..write(_escapePipe(source.path))
      ..write(':${source.startLine}:${source.startColumn}')
      ..write(' • ')
      ..writeln(_escapePipe(issue.rule.name));
  }

  String _escapePipe(String input) {
    final result = StringBuffer();
    for (final c in input.codeUnits) {
      if (c == _backslash || c == _pipe) {
        result.write('\\');
      }
      result.writeCharCode(c);
    }
    return result.toString();
  }

  static const _backslash = 0x5c; // '\'
  static const _pipe = 0x7c; // '|'
}
