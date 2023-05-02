#!/bin/bash

set -e

bash tool/helper/dart_coverage_helper.sh

sleep 1

dart run test test/all.dart --chain-stack-traces --run-skipped --coverage=coverage || EXIT_CODE=$?;

dart run coverage:format_coverage  --check-ignore -i coverage/test/all.dart.vm.json -o coverage/lcov/coverage.info -l --report-on=lib

# lcov --remove coverage/lcov/coverage.info "**/lib/src/plugin/*" -o coverage/lcov/coverage.info

genhtml coverage/lcov/coverage.info -o coverage/html -q

sleep 1

exit ${EXIT_CODE}
