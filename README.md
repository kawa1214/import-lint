![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

# Why import lint?

The Import Lint package defines import lint rules and report on lints found in Dart code.

## 😻 Usage

1. You have lints configured in an `analysis_options.yaml` file at the root of your project.

- search_file_path_reg_exp: Specify a file paths to analyze.(RegExp)
- not_allow_import_reg_exps: Specify import rules not to allow.(List of RegExp)
- exclude_import_reg_exps: Specify exclude import rules.(List of RegExp)

Example

```
analyzer:
    plugins:
        - import_lint

import_lint:
    rules:
        use_case_rule:
            search_file_path_reg_exp: ".*use_case.dart$"
            not_allow_import_reg_exps: [".*use_case.dart"]
            exclude_import_reg_exps: [".*base_use_case.dart"]
        repository_rule:
            search_file_path_reg_exp: ".*repository.dart$"
            not_allow_import_reg_exps: [".*repository.dart", ".*use_case.dart"]
            exclude_import_reg_exps: []
        # add custom rules...

```

By adding import_lint plugin to get the warnings directly in your IDE by configuring.

![vscode](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/vscode.png)

1. Add import_lint as a dev_dependencies in pubspec.yamls.

```
dart pub add --dev import_lint
```

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
            search_file_path_reg_exp: ".*use_case.dart$"
            not_allow_import_reg_exps: [".*use_case.dart"]
            exclude_import_reg_exps: [".*base_use_case.dart"]
        repository_rule:
            search_file_path_reg_exp: ".*repository.dart$"
            not_allow_import_reg_exps: [".*repository.dart", ".*use_case.dart"]
            exclude_import_reg_exps: []

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
- [ ] Directory Support
- [ ] Add Test