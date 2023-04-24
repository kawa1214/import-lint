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
  void test_fromString() {
    expect(
        SeverityExtension.fromAnalysisErrorSeverity('error'), Severity.error);
    expect(SeverityExtension.fromAnalysisErrorSeverity('warning'),
        Severity.warning);
    expect(SeverityExtension.fromAnalysisErrorSeverity('info'), Severity.info);
    expect(SeverityExtension.fromAnalysisErrorSeverity(null), Severity.warning);
    expect(SeverityExtension.fromAnalysisErrorSeverity(''), Severity.warning);
    expect(SeverityExtension.fromAnalysisErrorSeverity('unknown'),
        Severity.warning);
  }

  void test_toAnalysisErrorSeverity() {
    expect(Severity.error.toAnalysisErrorSeverity, AnalysisErrorSeverity.ERROR);
    expect(Severity.warning.toAnalysisErrorSeverity,
        AnalysisErrorSeverity.WARNING);
    expect(Severity.info.toAnalysisErrorSeverity, AnalysisErrorSeverity.INFO);
  }
}
