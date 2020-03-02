#!/bin/sh

set -e
set -u

LATEST_TAG=$1
BASE_PATH="$(pwd)/docker"

if [ $# -eq 0 ]; then
    echo "Usage: ./version.sh <tag or branch>"
    exit
fi

export VERSION=$LATEST_TAG
export UBUNTU_VERSION=18.04

if [ ! -d "$BASE_PATH" ]; then
    echo "Directory no found for \"${BASE_PATH}\""
    exit 1
fi

echo "Generating Dockerfile for Ubuntu Linux v$UBUNTU_VERSION x86_64"

rm -rf "${BASE_PATH}/Dockerfile"

envsubst \$UBUNTU_VERSION,\$VERSION <"${BASE_PATH}/tmpl.Dockerfile" >"${BASE_PATH}/Dockerfile"

echo "Dockerfile $VERSION were created successfully!"
