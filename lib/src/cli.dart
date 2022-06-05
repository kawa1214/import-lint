import 'dart:io' as io;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:import_lint/import_lint.dart';

final logger = Logger.standard();

Future<void> run(List<String> args) async {
  final progress = logger.progress('Analyzing');

  final collection = AnalysisContextCollectionImpl(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    includedPaths: [absoluteNormalizedPath('./')],
  );
  final context = collection.contexts.take(1).first;

  await runLinter(context);

  progress.finish(showTiming: true);
}

Future<void> runLinter(DriverBasedAnalysisContext context) async {
  final targetPath = './';
  final options = getOptions(context);

  final files = collectFiles(targetPath)
      .map((file) => absoluteNormalizedPath(file.path))
      .map((path) => io.File(path))
      .toList();

  final errors = <AnalysisError>[];

  for (final file in files) {
    final fileErrors = await getErrors(options, context, file.path);
    errors.addAll(fileErrors);
  }

  final buffer = StringBuffer();
  final reporter = Reporter(buffer);

  reporter.writeLints(errors);

  logger.stdout(buffer.toString());
}

class Reporter {
  const Reporter(this.out);
  final StringBuffer out;

  void writeLints(Iterable<AnalysisError> errors) {
    errors.forEach((error) => _writeLint(error));

    out
      ..writeln('')
      ..write('${errors.length} issues found.');
  }

  void _writeLint(AnalysisError error) {
    out
      ..write('   ')
      ..write(error.severity.name)
      ..write(' • ')
      ..write(_escapePipe(error.location.file))
      ..write(':${error.location.startLine}:${error.location.startColumn}')
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
