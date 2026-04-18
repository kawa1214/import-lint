// Coverage-only entry point. The generator
// `tool/helper/dart_coverage_helper.sh` writes
// `test/helper/coverage_test.dart` (git-ignored). Running this entry
// point WITHOUT first running the generator will fail to analyze —
// that is expected. Use `tool/test.sh` (which runs the generator
// first) for coverage runs.

// ignore_for_file: uri_does_not_exist, unused_import
import 'coverage_test.dart';
import '../all.dart' as all;

void main() => all.main();
