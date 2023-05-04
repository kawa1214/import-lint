import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show AnalysisErrorSeverity;
import 'package:import_lint/src/config/severity.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SeverityTest);
  });
}

@reflectiveTest
class SeverityTest {
  void test_severity_parseFromString() {
    expect(SeverityExtension.fromString('error'), Severity.error);
    expect(SeverityExtension.fromString('warning'), Severity.warning);
    expect(SeverityExtension.fromString('info'), Severity.info);
    expect(SeverityExtension.fromString(null), Severity.warning);
    expect(SeverityExtension.fromString(''), Severity.warning);
    expect(SeverityExtension.fromString('unknown'), Severity.warning);
  }

  void test_severity_convertToAnalysisErrorSeverity() {
    expect(Severity.error.toAnalysisErrorSeverity, AnalysisErrorSeverity.ERROR);
    expect(Severity.warning.toAnalysisErrorSeverity,
        AnalysisErrorSeverity.WARNING);
    expect(Severity.info.toAnalysisErrorSeverity, AnalysisErrorSeverity.INFO);
  }
}
