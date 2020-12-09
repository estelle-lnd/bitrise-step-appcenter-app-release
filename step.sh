#!/bin/bash
#
# upload an app from Bitrise to AppCenter
#
# API details: https://docs.microsoft.com/en-us/appcenter/distribution/uploading
#

set -o errexit
set -o pipefail
set -o nounset

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=${2:-}
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

echo_info "Starting AppCenter app upload at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

validate_required_input "appcenter_api_token" ${appcenter_api_token:-}
validate_required_input "appcenter_name" ${appcenter_name:-}
validate_required_input "appcenter_org" ${appcenter_org:-}
validate_required_input "artifact_path" ${artifact_path:-}
validate_required_input "distribution_groups" ${distribution_groups:-}

#APPCENTER_ACCESS_TOKEN=${appcenter_api_token}
RELEASE_NOTES_ENCODED="$( jq --null-input --compact-output --arg str "${release_notes:-}" '$str' )"

if [ ! -f "${artifact_path}" ]; then
	echo_fail "[!] File ${artifact_path} does not exist"
fi

if [ "${appcenter_api_token}" == "TestApiToken" ]
then
	echo_done "Running in test mode: all the parameters look good!"
	exit 0
fi

npm install appcenter-cli
appcenter login --token ${appcenter_api_token} --debug
appcenter distribute release --app "${appcenter_org}/${appcenter_name}" --file "${artifact_path}" --group "${distribution_groups}" --release-notes "${release_notes:-}" --debug
echo_done "Completed AppCenter app upload at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
