#!/bin/bash
# this script runs at container runtime to setup and invoke terraform based
# on settings provided by the environment
set -e -o pipefail

aws --version
terraform --version

THISTMPDIR=$(mktemp -d)
trap 'rm -rf "${THISTMPDIR}"' EXIT

LOCAL_RELEASE_DIR="${THISTMPDIR}"
LOCAL_RELEASE_ARCHIVE="${LOCAL_RELEASE_DIR}/release.tgz" # we assume tar gz format for now for simplicity

# note: we could support other storage systems here (like GCP), but installing
# multiple tools might bloat the image, so if it comes to that we might
# want separate images for them
aws configure set default.s3.signature_version s3v4
aws s3 cp "${RELEASE_S3_URL}" "${LOCAL_RELEASE_ARCHIVE}"

cd "${LOCAL_RELEASE_DIR}"
tar zxvf "${LOCAL_RELEASE_ARCHIVE}"

# if the release has a bootstrap script, run that now
[ -f ./.docker-release.bootstrap.sh ] && ./.docker-release.bootstrap.sh

# translate each BACKEND_ environment variable into a line in backend.hcl
echo -n > backend.hcl
for var in $(compgen -e); do
	if [[ "${var}" =~ ^BACKEND_ ]]; then
		# note: map configs like `map.key = "value"` aren't supported here, but
		# no backends appear to require that support anyway
		config_key=$(echo "${var}" | sed -r "s/^BACKEND_//g" | tr '[:upper:]' '[:lower:]')
		config_val="${!var}"
		echo "Using env var ${var} as backend config var: ${config_key}"
		echo "${config_key} = \"${config_val}\"" >> backend.hcl
	fi
done

# terraform >= 0.9: the backend type is defined in the released files `terraform` section
terraform init -input=false -no-color -reconfigure -backend=true -backend-config=backend.hcl

# TODO: terraform >= 0.8 < 0.9:
# terraform remote config -backend=${BACKEND_NAME} ${BACKEND_CONFIGS}`;

# anything older than terraform 0.8 is not supported

# hand over the remainder of execution to a release-provided script since so
# that each substack can control exactly terraform is invoked
./.docker-release.sh "${ACTION}"
