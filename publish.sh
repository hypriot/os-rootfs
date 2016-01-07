#!/bin/bash -e

TAG=$(git describe --exact-match $CIRCLE_SHA1 2>/dev/null)
if [ -z "${TAG}" ]; then
  echo "No version tag detected. Skip publishing."
  exit 0
fi
