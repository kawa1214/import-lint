![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

# Why import_lint?

The [import_lint package](https://pub.dev/packages/import_lint) defines rules to restrict imports and performs static analysis. It was inspired by [eslint/no-restricted-paths](https://github.com/import-js/eslint-plugin-import/blob/main/docs/rules/no-restricted-paths.md).

## 😻 Usage

1. Add import_lint as a dev_dependencies in pubspec.yamls.

```
flutter pub add --dev import_lint

or

dart pub add --dev import_lint
```

2. You have lints configured in an `analysis_options.yaml` file at the root of your project.

- target: Define the file paths of the targets to be restricted using glob patterns.
- from: Define the paths that are not allowed to be used in imports using glob patterns.
- target_except: Define the exception paths for the target using glob patterns.
- from_except: Define the exception paths for the 'from' rule using glob patterns.

Example of `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - import_lint

import_lint:
  rules:
    import_rule:
      target: "target/*_target.dart"
      from: ["from/**/*.dart"]
      target_except: ["target/except_target.dart"]
      from_except: ["from/except_from.dart"]
    package_rule:
      target: "package:import_lint/import_lint.dart"
      from: ["/**/*.dart"]
      target_except: []
      from_except: []
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

## Example

`analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - import_lint

import_lint:
  rules:
    import_rule:
      target: "target/*_target.dart"
      from: ["from/**/*.dart"]
      target_except: ["target/except_target.dart"]
      from_except: ["from/except_from.dart"]
    package_rule:
      target: "package:import_lint/import_lint.dart"
      from: ["/**/*.dart"]
      target_except: []
      from_except: []
```

`files`

```dart
- lib
    - target
        - test_target.dart

            class TestTarget {}

        - except_target.dart

            class ExceptTarget {}

    - from
        - test_from.dart

            import 'package:import_analyzer_test/target/test_target.dart';
            import 'package:import_analyzer_test/target/except_target.dart';
            class TestFrom {}

        - except_from.dart

            import 'package:import_analyzer_test/target/test_target.dart';
            class ExceptFrom {}

    - package
        - package.dart

            import 'package:import_lint/import_lint.dart';
            class Package {}
```

`output`

```{dart}

from > test_from > import 'package:import_analyzer_test/target/test_target.dart';
package > package.dart > import 'package:import_lint/import_lint.dart';

```

## Option

### Rule Severities

To change the severity of a rule, add a `severity` key to the rule configuration.

- `warning` (default)
- `error` (exit code 1 when lint is found)

```yaml
import_lint:
  severity: "error"
  rules: ...
```

## Contribution

Welcome PRs!

You can develop locally by setting the path to an absolute path as shown below.
`tools/analyzer_plugin/pubspec.yaml`

```
dependencies:
  import_lint: ^x.x.x → import_lint:/Users/xxx/import-lint
```
