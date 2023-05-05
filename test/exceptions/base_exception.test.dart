import 'package:import_lint/src/exceptions/internal_exception.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseExceptionTest);
  });
}

@reflectiveTest
class BaseExceptionTest {
  void test_toString() async {
    final exception = InternalException('test');
    expect(exception.toString(), 'test');
  }
}
