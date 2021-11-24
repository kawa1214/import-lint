![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

[![codecov](https://codecov.io/gh/kawa1214/import-lint/branch/main/graph/badge.svg?token=H5PJUT9ZTP)](https://codecov.io/gh/kawa1214/import-lint)

# Why import lint?

The Import Lint package defines import lint rules and report on lints found in Dart code.

## 😻 Usage

1. Add import_lint as a dev_dependencies in pubspec.yamls.

```
flutter pub add --dev import_lint

or

dart pub add --dev import_lint
```

2. You have lints configured in an `analysis_options.yaml` file at the root of your project.

- target_file_path: Specify a file paths to analyze.
- not_allow_imports: Specify import rules not to allow.
- exclude_imports: Specify exclude import rules.

Example

```
analyzer:
    plugins:
        - import_lint

import_lint:
    rules:
        use_case_rule:
            target_file_path: "/**/use_case/*_use_case.dart"
            not_allow_imports: ["/**/use_case/*_use_case.dart"]
            exclude_imports: ["/lib/use_case/base_use_case.dart"]
        repository_rule:
            target_file_path: "/**/repository/*_repository.dart"
            not_allow_imports:
                ["/**/use_case/*_repository.dart", "/**/use_case/*_use_case.dart"]
            exclude_imports: []
        # add custom rules...

```

By adding import_lint plugin to get the warnings directly in your IDE by configuring.

![vscode](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/vscode.png)

3. run import_lint(CLI Support)

```
flutter pub run import_lint
```
or
```
dart pub run import_lint
```

## Result

- Passed

`output`
```
No issues found! 🎉
```

- Failed Example

`analysis_options.yaml`

```
analyzer:
    plugins:
        - import_lint

import_lint:
    rules:
        use_case_rule:
            target_file_path: "/**/use_case/*_use_case.dart"
            not_allow_imports: ["/**/use_case/*_use_case.dart"]
            exclude_imports: ["/lib/use_case/base_use_case.dart"]
        repository_rule:
            target_file_path: "/**/repository/*_repository.dart"
            not_allow_imports:
                ["/**/use_case/*_repository.dart", "/**/use_case/*_use_case.dart"]
            exclude_imports: []

```

`files`

```
- lib
    - repository
        - test_one_repository.dart

            import 'package:import_analyzer_test/repository/test_two_repository.dart';
            import 'package:import_analyzer_test/use_case/test_one_use_case.dart';
            class TestOneRepository {}

        - test_two_repository.dart
        
            class TestTwoRepository {}
    
    - use_case

        - test_one_use_case.dart
        
            import 'package:import_analyzer_test/use_case/base_use_case.dart';
            class TestOneUseCase extends BaseUseCase {}
        
        - test_two_use_case.dart
        
            import 'package:import_analyzer_test/repository/test_one_repository.dart';
            import 'package:import_analyzer_test/use_case/test_one_use_case.dart';
            class TestTwoUseCase {}
```


`output`

```{dart}
use_case_rule • package:import_analyzer_test/use_case/test_two_use_case.dart:2 • import 'package:import_analyzer_test/use_case/test_one_use_case.dart'
repository_rule • package:import_analyzer_test/repository/test_one_repository.dart:1 • import 'package:import_analyzer_test/repository/test_two_repository.dart'
repository_rule • package:import_analyzer_test/repository/test_one_repository.dart:2 • import 'package:import_analyzer_test/use_case/test_one_use_case.dart'

3 issues found.
```

## 🧤 Features

- [x] Analyzer Plugin Support
- [x] CLI Support
- [x] Ignore Import Line
- [x] Add Test