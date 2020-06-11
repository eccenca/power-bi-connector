#!/usr/bin/env bash
# Use the unofficial bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail; export FS=$'\n\t'

SOURCES_PATH=${1:-CMEMPowerBIConnector}
TARGET_PATH=${2:-target}
FILE_PREFIX=${3:-eccenca-PowerBIConnector}
VERSION=$(git describe --always --tags)
mkdir -p "./${TARGET_PATH}"

sed -i "s/SNAPSHOT/${VERSION}/g" CMEMPowerBIConnector/resources.resx
zip -r -j "${TARGET_PATH}/${FILE_PREFIX}-${VERSION}.mez" "${SOURCES_PATH}"/*
git checkout CMEMPowerBIConnector/resources.resx

echo "Zipped '${SOURCES_PATH}/*' as '${TARGET_PATH}/${FILE_PREFIX}-${VERSION}.mez'" 
