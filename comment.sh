#!/bin/sh
set -eu
# To use this script, the following environment variables must be set
# - GITHUB_TOKEN
# The token for the user that will post the comment. If the event type is
# pull_request_target, then the token can be used for making comments on pull
# requests through the API.
# The token can be found in the "github" context at "github.token".
# pull_request_target:
# https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request_target
# The github context for GitHub Actions workflows:
# https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context
#
# Additionally, these can be overridden by setting them in the calling
# environment
#
# The user of the GITHUB_TOKEN if it is a Personal Access Token
GITHUB_TOKEN_USER="${GITHUB_TOKEN_USER:-"github-actions"}"
#
# The URL for the homepage of the rendered preview
PREVIEW_URL="${PREVIEW_URL:-"https://pr.texasbutterfliesmonitoring.org/1"}"
# The username/repository of the GitHub repository that hosts the renderer
# workflow
RENDER_REPOSITORY="mawillcockson/pr.texasbutterfliesmonitoring.org"
# The name of the file that describes the renderer part of the workflow, in the
# RENDER_REPOSITORY
WORKFLOW_FILE="${WORKFLOW_FILE:-"pull_request.yaml"}"
# The api.github.com endpoint that can receive post requests for the pull
# request that triggered the dispatch workflow
# This can be found in the context "github.event.pull_request.issue_url".
# More info on the endpoint:
# https://docs.github.com/en/rest/reference/issues#create-an-issue-comment
PULL_REQUEST_COMMENTS_URL="${PULL_REQUEST_COMMENTS_URL:-"https://api.github.com/repos/mawillcockson/TXButterflies.github.io/issues/1"}"
export PULL_REQUEST_COMMENTS_URL


TEMP_FILE="$(mktemp)"
export TEMP_FILE

printf \
'# DO NOT MERGE BEFORE PREVIEWING THE CHANGES

[Preview the changes at this link.](%s)

If you have visited the above link before, you may have to refresh your browser to see the changes. This is due to browsers caching data from websites. [This link has more information about this](https://refreshyourcache.com/en/cache/).

If the preview looks fine, you can merge the pull request.

If the preview is not fine, or not available, [there are logs available at this link.](<https://github.com/%s/actions/workflows/%s?query=event%3Aworkflow_dispatch+branch%3Amain>)

_note: this comment was generated automatically_' \
    "${PREVIEW_URL}" \
    "${RENDER_REPOSITORY}" \
    "${WORKFLOW_FILE}" \
    | jq '{"body":.}' --raw-input --slurp --compact-output --exit-status \
> "${TEMP_FILE}"

curl \
    --request POST \
    --header "Accept: application/vnd.github.v3+json" \
    --user "${GITHUB_TOKEN_USER}:${GITHUB_TOKEN}" \
    --data "@${TEMP_FILE}" \
    --url "${PULL_REQUEST_COMMENTS_URL}/comments"

rm "${TEMP_FILE}"
