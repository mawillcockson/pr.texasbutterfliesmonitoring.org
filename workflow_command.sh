#!/bin/bash
# $PERSONAL_ACCESS_TOKEN is a token generated for the account hosting the
# workflow file, not the account running this script. Generate one here:
# https://github.com/settings/tokens/new
set -eu
# jq requires input
echo "{}" \
    | jq --compact-output '{
    "ref": $github_ref,
    "inputs": {
        "pull_request_id": $pull_request_id,
    }
}' \
    --arg github_ref "${GITHUB_REF}" \
    --arg pull_request_id "${PULL_REQUEST_ID}" \
    | curl \
    --request POST \
    --header "Accept: application/vnd.github.v3+json" \
    --user "mawillcockson:${PERSONAL_ACCESS_TOKEN}" \
    --post301 --post302 --post303 \
    --data "@-" \
    'https://api.github.com/repos/mawillcockson/pr.texasbutterfliesmonitoring.org/actions/workflows/pull_request.yaml/dispatches'
