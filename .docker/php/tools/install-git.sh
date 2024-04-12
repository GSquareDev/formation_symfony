#!/bin/sh

set -ex
apk add --no-cache git=${GIT_VERSION} zip=${ZIP_VERSION} unzip=${UNZIP_VERSION} patch=${PATCH_VERSION}