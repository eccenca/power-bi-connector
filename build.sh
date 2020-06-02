#!/usr/bin/env bash
# Use the unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail; export FS=$'\n\t'

SOURCES_PATH=${1:-CMEMPowerBIConnector}
TARGET_PATH=${2:-target}
FILE_PREFIX=${3:-eccenca-PowerBIConnector}
VERSION=$(git describe --always --dirty --tags)
mkdir -p "./${TARGET_PATH}"

zip -r -j "${TARGET_PATH}/${FILE_PREFIX}-${VERSION}.mez" "${SOURCES_PATH}"/*

echo "Zipped '${SOURCES_PATH}/*' as '${TARGET_PATH}/${FILE_PREFIX}-${VERSION}.mez'" 
