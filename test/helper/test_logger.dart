import 'package:cli_util/cli_logging.dart'
    show Logger, Ansi, Progress, SimpleProgress;

class TestLogger implements Logger {
  const TestLogger(this._buf);
  final StringBuffer _buf;

  @override
  Ansi get ansi => throw UnimplementedError();

  @override
  void flush() {}

  @override
  bool get isVerbose => throw UnimplementedError();

  @override
  Progress progress(String message) {
    return SimpleProgress(this, message);
  }

  @override
  void stderr(String message) {}

  @override
  void stdout(String message) {}

  @override
  void trace(String message) {}

  @override
  void write(String message) {
    _buf.write(message);
  }

  @override
  void writeCharCode(int charCode) {}
}
