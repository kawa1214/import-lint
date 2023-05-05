![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

<p>
  <img src="https://github.com/kawa1214/import-lint/actions/workflows/test.yaml/badge.svg?branch=main">
  <img src="https://codecov.io/gh/kawa1214/import-lint/branch/main/graph/badge.svg?token=H5PJUT9ZTP" />
</p>

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
      target: "package:example/target/*.dart"
      from: "package:example/from/*.dart"
      except: ["package:example/from/except.dart"]
    self_rule:
      target: "package:example/self/*.dart"
      from: "package:example/self/*.dart"
      except: []
    only_rule:
      target: "package:example/*[!only]/*.dart"
      from: "package:example/only_from/*.dart"
      except: []
    package_rule:
      target: "package:example/**/*.dart"
      from: "package:import_lint/*.dart"
      except: []
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

[example/analysis_options.yaml](https://github.com/kawa1214/import-lint/blob/main/example/analysis_options.yaml)

```yaml
analyzer:
  plugins:
    - import_lint

import_lint:
  rules:
    example_rule:
      target: "package:example/target/*.dart"
      from: "package:example/from/*.dart"
      except: ["package:example/from/except.dart"]
    self_rule:
      target: "package:example/self/*.dart"
      from: "package:example/self/*.dart"
      except: []
    only_rule:
      target: "package:example/*[!only]/*.dart"
      from: "package:example/only_from/*.dart"
      except: []
    package_rule:
      target: "package:example/**/*.dart"
      from: "package:import_lint/*.dart"
      except: []
```

`files`

[example/lib](https://github.com/kawa1214/import-lint/tree/main/example/lib)

`output`

```dart
$ dart run import_lint

Analyzing...
   warning • /example/lib/not/1.dart:1:8 • package:example/only_from/1.dart • only_rule
   warning • /example/lib/target/1.dart:2:8 • package:example/from/test.dart • example_rule
   warning • /example/lib/self/1.dart:1:8 • package:example/self/2.dart • self_rule
   warning • /example/lib/package/1.dart:1:8 • package:import_lint/import_lint.dart • package_rule

4 issues found.
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
