/// Defines the possible severity levels for the import lint tool.
enum Severity {
  /// Reported as an error and causes the CLI to exit with code 1.
  error,

  /// Reported as a warning. Default when nothing is configured.
  warning,

  /// Reported as an info-level diagnostic.
  info,
}

/// Helpers for constructing [Severity] values from external input
/// (YAML, CLI args, etc.).
extension SeverityExtension on Severity {
  /// Returns the [Severity] matching [value] or [Severity.warning]
  /// when [value] is `null` or unrecognized.
  static Severity fromString(Object? value) {
    switch (value) {
      case 'error':
        return Severity.error;
      case 'warning':
        return Severity.warning;
      case 'info':
        return Severity.info;
      default:
        return Severity.warning;
    }
  }
}
