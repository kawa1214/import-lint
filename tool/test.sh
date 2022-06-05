#!/bin/bash

set -e

bash tool/helper/dart_coverage_helper.sh

sleep 1

dart run test test/all.dart --chain-stack-traces -t presubmit-only --run-skipped --coverage=coverage || EXIT_CODE=$?;

dart run coverage:format_coverage -i coverage/test/all.dart.vm.json -o coverage/lcov/coverage.info -l --report-on=lib

genhtml coverage/lcov/coverage.info -o coverage/html -q

sleep 1

exit ${EXIT_CODE}
