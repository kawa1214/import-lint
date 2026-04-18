/// Defines the possible severity levels for the import lint tool.
enum Severity {
  error,
  warning,
  info,
}

extension SeverityExtension on Severity {
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
