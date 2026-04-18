/// Public API for the `import_lint` analysis-server plugin and its CLI.
///
/// This library re-exports the configuration and analyzer types that
/// callers need to drive lint checks programmatically:
///
/// * [AnalysisOptions] — wrapper around `analysis_options.yaml`
/// * [Config] — typed view of the `import_lint:` block
/// * [Analyzer] — entry point that walks a Dart source tree and
///   reports import-rule violations
///
/// Most users will not import this library directly — they enable the
/// plugin via `analysis_options.yaml` and read warnings from the
/// analyzer. See the README for end-user setup.
library;

export 'package:import_lint/src/analyzer/analyzer.dart' show Analyzer;
export 'package:import_lint/src/config/analysis_options.dart'
    show AnalysisOptions;
export 'package:import_lint/src/config/config.dart' show Config;
