import 'dart:io' as io;

import 'package:glob/glob.dart';

class Paths {
  const Paths(this.value);

  factory Paths.ofDartFile({required String directoryPath}) {
    final dartFileRegExp = Glob('$directoryPath/lib/**/*.dart');
    final directory = io.Directory(directoryPath);
    final result = <Path>[];
    for (final entry
        in directory.listSync(recursive: true, followLinks: false)) {
      if (dartFileRegExp.matches(entry.path)) {
        result.add(Path(entry.path));
      }
    }
    return Paths(result);
  }

  final List<Path> value;
}

class Path {
  const Path(this.value);
  final String value;
}
