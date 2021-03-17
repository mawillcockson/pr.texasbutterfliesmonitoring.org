#!/bin/bash
# $PERSONAL_ACCESS_TOKEN is a token generated for the account hosting the
# workflow file, not the account running this script. Generate one here:
# https://github.com/settings/tokens/new
curl \
    --request POST \
    --header "Accept: application/vnd.github.v3+json" \
    --user "mawillcockson:${PERSONAL_ACCESS_TOKEN}" \
    --post301 --post302 --post303 \
    --data \
"{
    \"ref\": \"${GITHUB_REF}\",
    \"inputs\": {
        \"pull_request_id\": \"${PULL_REQUEST_ID}\",
    }
}" \
    'https://api.github.com/repos/mawillcockson/pr.texasbutterfliesmonitoring.org/actions/workflows/pull_request.yaml/dispatches'
