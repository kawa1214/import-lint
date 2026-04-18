![cover](https://raw.githubusercontent.com/kawa1214/import-lint/main/resources/cover.png)

<p>
  <a href="https://github.com/kawa1214/import-lint/actions/workflows/test.yaml">
    <img src="https://github.com/kawa1214/import-lint/actions/workflows/test.yaml/badge.svg?branch=main">
  </a>
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
plugins:
  import_lint: <version number>

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

> **Note:** `import_lint` requires Dart 3.10 or later (analyzer plugin support
> was added in Dart 3.10 / Flutter 3.38). The top-level `plugins:` section is
> the new analyzer plugin system. After any change to the `plugins:` section,
> the Dart Analysis Server must be restarted to see the effects
> (VS Code: *Dart: Restart Analysis Server*).

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
plugins:
  import_lint:
    path: ..

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

> **Note on IDE severity:** The `severity: "error"` setting is honored by
> `dart run import_lint` (exit code 1). In the IDE, `analysis_server_plugin`
> registers a fixed `warning` severity. To see import_lint errors as errors
> in the IDE, add this to `analysis_options.yaml`:
>
> ```yaml
> analyzer:
>   errors:
>     import_lint: error
> ```

## Contribution

Welcome PRs!

To develop locally, clone the repo and enable the plugin from a local path in
your host project's `analysis_options.yaml`:

```yaml
plugins:
  import_lint:
    path: /path/to/your/import-lint
    diagnostics:
      import_lint: true
```

For CLI use (`dart run import_lint`), also add it under `dev_dependencies`:

```yaml
dev_dependencies:
  import_lint:
    path: /path/to/your/import-lint
```

Then run `dart pub get` in the host project and restart the Dart Analysis
Server. No separate `tools/analyzer_plugin` directory is needed — the plugin
entry point is `lib/main.dart` in this package.
