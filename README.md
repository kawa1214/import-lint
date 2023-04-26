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
- except: Define the exception paths for the 'from' rule using glob patterns.

Example of `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - import_lint

import_lint:
  rules:
    example_rule:
      target: "package:example/target/*_target.dart"
      from: "package:example/from/*.dart"
      expect: ["package:example/from/expect.dart"]
    self_rule:
      target: "package:example/self/*.dart"
      from: "package:example/self/*.dart"
      expect: []
    only_rule:
      target: "package:example/only/*.dart"
      from: "package:example/[^only_from]**/*.dart"
      expect: []
    package_rule:
      target: "package:import_lint/import_lint.dart"
      from: "package:example/**/*.dart"
      expect: []
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
    example_rule:
      target: "package:example/target/*_target.dart"
      from: "package:example/from/*.dart"
      expect: ["package:example/from/expect.dart"]
    self_rule:
      target: "package:example/self/*.dart"
      from: "package:example/self/*.dart"
      expect: []
    only_rule:
      target: "package:example/[!only]**/*.dart"
      from: "package:example/only_from/*.dart"
      expect: []
    package_rule:
      target: "package:example/**/*.dart"
      from: "package:import_lint/import_lint.dart"
      expect: []
```

`files`

```dart
- lib
    // example_rule
    - from
        - except.dart

            class ExceptFrom {}

        - test_from.dart

            class TestFrom {}

    - target
        - test_target.dart

            import 'package:example/from/except.dart';
            import 'package:example/from/test_from.dart';

            class TestTarget {}

    // self_rule
    - self
        - self1.dart

            import 'package:example/self/self2.dart';
            import 'package:example/only_from/only_from.dart';

            class Self1 {}

        - self2.dart

            class Self2 {}

    // only_rule
    - only_from
        - only_from.dart

            class OnlyFrom {}

    - only
        - only.dart
            import 'package:example/only_from/only_from.dart';

    // package_rule
    - package
        - package.dart

            import 'package:import_lint/import_lint.dart';
            class Package {}
```

`output`

```{dart}

example_rule
target > test_target.dart > import 'package:example/from/test_from.dart'

self_rule
self > slef1.dart > import 'package:example/self/self2.dart'

only_rule
self > self.dart >  import 'package:example/only_from/only_from.dart'

package_rule
package > package.dart > import 'package:import_lint/import_lint.dart'
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
