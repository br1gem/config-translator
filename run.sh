#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "$(uname -s)" == Darwin ]]; then
    exec xcrun swift run --package-path "$project_dir" config-translator "$@"
fi

exec swift run --package-path "$project_dir" config-translator "$@"