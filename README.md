![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

# Why import lint?

The Import Lint package defines import lint rules and report on lints found in Dart code.

## 😻 Usage

1. Add import_lint as a dev_dependencies in pubspec.yamls.

```
flutter pub add --dev import_lint

or

dart pub add --dev import_lint
```

2. Add import lints into your `analysis_options.yaml`

````yaml
analyzer:
    plugins:
        - import_lint
import_lint:
  rules:
    use_case_rule:
      target_file_path: "use_case/*_use_case.dart"
      not_allow_imports: ["use_case/*_use_case.dart"]
      exclude_imports: ["use_case/base_use_case.dart"]
````
3. Plugin uses file globs to match file paths.


4. It considers the following paths on your project:
   1. Remove remove absolute file paths and use relative, example: `/home/user/project/lib/file.dart` became `lib/file.dart` 
   2. For each file inside lib/**, remove lib/, example: `lib/folder/file.dart` became `folder/file.dart`
   3. For each file inside test/**, do not remove test/, example: `test/folder/file.dart` is `test/folder/file.dart`
   

    So, `/home/user/project/lib/folder/file.dart` became `folder/file.dart` and `/home/user/project/test/folder/file.dart` became `test/folder/file.dart`

5. Available rules configuration
- target_file_path: Specify a file paths to analyze.
- not_allow_imports: Specify import rules not to allow.
- exclude_imports: Specify imports that are excluded, or, allowed for this rule.
- ignore_files: Files to ignore import rules

Example

```
analyzer:
    plugins:
        - import_lint

import_lint:
    rules:
        use_case_rule:
            target_file_path: "use_case/*_use_case.dart"
            not_allow_imports: ["use_case/*_use_case.dart"]
            exclude_imports: ["use_case/base_use_case.dart"]
        repository_rule:
            target_file_path: "repository/*_repository.dart"
            not_allow_imports:
                [
                    "use_case/*_use_case.dart",
                    "repository/*_repository.dart",
                    "space\ test/*.dart",
                    "repository/sub/**/*.dart",
                ]
            exclude_imports: []
        package_rule:
            target_file_path: "**/*.dart"
            not_allow_imports: ["package:import_lint/import_lint.dart"]
            exclude_imports: []
        # add custom rules...

```

By adding import_lint plugin to get the warnings directly in your IDE by configuring.

![vscode](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/vscode.png)

3. run import_lint(CLI Support)

```
flutter run import_lint
```

or

```
dart run import_lint
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
            target_file_path: "use_case/*_use_case.dart"
            not_allow_imports: ["use_case/*_use_case.dart"]
            exclude_imports: ["use_case/base_use_case.dart"]
        repository_rule:
            target_file_path: "repository/*_repository.dart"
            not_allow_imports:
                [
                    "use_case/*_use_case.dart",
                    "repository/*_repository.dart",
                    "space\ test/*.dart",
                    "repository/sub/**/*.dart",
                ]
            exclude_imports: []
        package_rule:
            target_file_path: "**/*.dart"
            not_allow_imports: ["package:import_lint/import_lint.dart"]
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
            import 'package:import_lint/import_lint.dart';
            class TestTwoUseCase {}
```

`output`

```{dart}
use_case_rule • package:import_analyzer_test/use_case/test_two_use_case.dart:2 • import 'package:import_analyzer_test/use_case/test_one_use_case.dart'
repository_rule • package:import_analyzer_test/repository/test_one_repository.dart:1 • import 'package:import_analyzer_test/repository/test_two_repository.dart'
repository_rule • package:import_analyzer_test/repository/test_one_repository.dart:2 • import 'package:import_analyzer_test/use_case/test_one_use_case.dart'
package_rule • package:import_analyzer_test/repository/test_one_repository.dart:3 • import 'package:import_lint/import_lint.dart';

4 issues found.
```

## 🧤 Features

- [x] Analyzer Plugin Support
- [x] CLI Support
- [x] Ignore Import Line
- [x] Add Test
