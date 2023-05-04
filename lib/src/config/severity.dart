import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show AnalysisErrorSeverity;

/// Defines the possible severity levels for the import lint tool.
enum Severity {
  error,
  warning,
  info,
}

extension SeverityExtension on Severity {
  AnalysisErrorSeverity get toAnalysisErrorSeverity {
    switch (this) {
      case Severity.error:
        return AnalysisErrorSeverity.ERROR;
      case Severity.warning:
        return AnalysisErrorSeverity.WARNING;
      case Severity.info:
        return AnalysisErrorSeverity.INFO;
    }
  }

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
