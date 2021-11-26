#!/bin/bash

set -e

bash tool/helper/dart_coverage_helper.sh

sleep 1

dart run test test/run.dart --chain-stack-traces -t presubmit-only --run-skipped --coverage=coverage || EXIT_CODE=$?;

dart run coverage:format_coverage --packages=.import_lint_packages -i coverage/test/run.dart.vm.json -o coverage/lcov/coverage.info -l

sleep 1

exit ${EXIT_CODE}
