import 'base_exception.dart';

class ArgumentException implements BaseException {
  const ArgumentException(this.message); // coverage:ignore-line
  final String message;
}
