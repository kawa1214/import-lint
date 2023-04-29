import 'base_exception.dart';

class InternalException implements BaseException {
  const InternalException(this.message); // coverage:ignore-line
  final String message;
}
