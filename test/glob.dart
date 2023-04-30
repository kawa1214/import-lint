import 'package:glob/glob.dart';

void main() {
  // final Glob pattern = Glob('[^abc|123]*.dart');
  // final List<String> files = ['abc.dart', 'def.dart', '123.dart', '456.dart'];
  // def.dart, 456.dart

  // final Glob pattern = Glob('[abc|123]*.dart');
  // final List<String> files = ['abc.dart', 'def.dart', '123.dart', '456.dart'];
  // abc.dart, 123.dart

  // final Glob pattern = Glob('/[!abc|def]**/*.dart');
  // final List<String> files = [
  //   '/abc/test.dart',
  //   '/def/test.dart',
  //   '/123/test.dart',
  //   '/456/test.dart'
  // ];
  // [/123/test.dart, /456/test.dart]

  final Glob pattern = Glob('[!foo]*.dart');
  final List<String> files = ['foo.dart', 'foo_test.dart'];

  final List<String> matchingFiles =
      files.where((file) => pattern.matches(file)).toList();

  print(matchingFiles);
}
