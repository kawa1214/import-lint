import 'dart:io' as io;

// ignore: implementation_imports
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/lint/io.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:import_lint/import_lint.dart';
import 'package:import_lint/src/rule.dart';
import 'package:import_lint/src/utils.dart';

// ignore: implementation_imports
final logger = Logger.standard();

Future<void> run(List<String> args) async {
  final progress = logger.progress('Analyzing');

  final options = _options();
  registerLintRules(options);

  await runLinter();

  progress.finish(showTiming: true);
}

void registerLintRules(LintOptions options) {
  final rules = options.rules.value.map((e) => ImportLintRule(e));
  rules.forEach((e) {
    Registry.ruleRegistry.register(e);
  });
}

LintOptions _options() {
  final collection = AnalysisContextCollectionImpl(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    includedPaths: [absoluteNormalizedPath('./')],
  );

  final context = collection.contexts.take(1).first;
  final rootDirectoryPath = context.contextRoot.root.path;

  final options = LintOptions.init(
    directoryPath: rootDirectoryPath,
    optionsFilePath: context.contextRoot.optionsFile!.path,
  );

  return options;
}

Future<void> runLinter() async {
  final targetPath = './';

  final lintOptions = LinterOptions()
    ..resourceProvider = PhysicalResourceProvider.INSTANCE;

  final linter = DartLinter(lintOptions);

  final files = collectFiles(targetPath)
      .map((file) => absoluteNormalizedPath(file.path))
      .map((path) => io.File(path))
      .toList();

  final errors = await linter.lintFiles(files);

  final buffer = StringBuffer();
  final reporter = Reporter(buffer);

  reporter.writeLints(errors);

  logger.stdout(buffer.toString());
}

class Reporter {
  const Reporter(this.out);
  final StringBuffer out;

  void writeLints(Iterable<AnalysisErrorInfo> errors) {
    var count = 0;
    for (final info in errors) {
      for (final e in info.errors.toList()) {
        if (e.message.contains('Found Import Lint Error')) {
          final location = info.lineInfo.getLocation(e.offset);
          _writeLint(
            e,
            line: location.lineNumber,
            column: location.columnNumber,
          );
          count += 1;
        }
      }
    }
    out
      ..writeln('')
      ..write('$count issues found.');
  }

  void _writeLint(AnalysisError error, {int? line, int? column}) {
    out
      ..write('   ')
      ..write(error.errorCode.errorSeverity.displayName)
      ..write(' • ')
      ..write(_escapePipe(error.source.fullName))
      ..write(':$line:$column')
      ..write(' • ')
      ..writeln(_escapePipe(error.message));
  }

  String _escapePipe(String input) {
    final result = StringBuffer();
    for (final c in input.codeUnits) {
      if (c == $backslash || c == $pipe) {
        result.write('\\');
      }
      result.writeCharCode(c);
    }
    return result.toString();
  }
}
