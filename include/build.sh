#!/bin/sh
# this script is part of the docker container build process
set -e -o pipefail

APK_RUNTIME_PACKAGES="python2 bash"
APK_BUILD_PACKAGES="py2-pip"

PIP_PACKAGES="awscli"

apk add -Uuv ${APK_RUNTIME_PACKAGES} ${APK_BUILD_PACKAGES}
pip install ${PIP_PACKAGES}
apk del --purge -v ${APK_BUILD_PACKAGES}

rm /var/cache/apk/*
