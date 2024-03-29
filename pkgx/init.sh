#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

cd "$(dirname "$0")"

main() {
  echo "ℹ️  pkgx"

  if [[ ! -x "$(command -v pkgx)" ]]; then
    echo "❌ pkgx command not found"
  fi

  pkgx install node
  pkgx install npm

  echo "✅ pkgx"
}

main "$@"
