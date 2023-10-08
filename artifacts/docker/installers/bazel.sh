#!/usr/bin/env bash

set -e

mkdir -p /tmp/installers
pushd /tmp/installers

DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
       wget unzip zip

BAZEL_VERSION=6.1.1
wget -O bazel-$BAZEL_VERSION-installer.sh https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh
chmod +x bazel-$BAZEL_VERSION-installer.sh
./bazel-$BAZEL_VERSION-installer.sh
rm -rf bazel-$BAZEL_VERSION-installer.sh

popd
