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
# - DISPATCH_RESULT
# The result of the dispatch step
# This is set as an output by ./dispatch.sh
#
# - RUN_DETAILS_URL
# The human-usable, HTML URL to the information about the build run triggered
# by the dispatch run
#
# - DISPATCH_DETAILS_URL
# The same style link as for RUN_DETAILS_URL, except for the dispatch GitHub
# Actions run itself (this run)
#
# Additionally, these can be overridden by setting them in the calling
# environment
#
# The user of the GITHUB_TOKEN if it is a Personal Access Token
GITHUB_TOKEN_USER="${GITHUB_TOKEN_USER:-"github-actions"}"
export GITHUB_TOKEN_USER
#
# The URL for the homepage of the rendered preview
PREVIEW_URL="${PREVIEW_URL:-"https://pr.texasbutterfliesmonitoring.org/1"}"
export PREVIEW_URL
# The username/repository of the GitHub repository that hosts the renderer
# workflow
RENDER_REPOSITORY="mawillcockson/pr.texasbutterfliesmonitoring.org"
export RENDER_REPOSITORY
# The name of the file that describes the renderer part of the workflow, in the
# RENDER_REPOSITORY
WORKFLOW_FILE="${WORKFLOW_FILE:-"pull_request.yaml"}"
export WORKFLOW_FILE
# The api.github.com endpoint that can receive post requests for the pull
# request that triggered the dispatch workflow
# This can be found in the context "github.event.pull_request.issue_url".
# More info on the endpoint:
# https://docs.github.com/en/rest/reference/issues#create-an-issue-comment
PULL_REQUEST_COMMENTS_URL="${PULL_REQUEST_COMMENTS_URL:-"https://api.github.com/repos/mawillcockson/TXButterflies.github.io/issues/1"}"
export PULL_REQUEST_COMMENTS_URL


if [ -z "${CI+"unset"}" ]; then
    for VAR in "GITHUB_TOKEN"; do
        CURRENT_VAL="$(printenv "${VAR}" || printf '')"
        if [ -z "${CURRENT_VAL}" ]; then
            printf "%s: " "${VAR}"
            read "${VAR}"
            export "${VAR}"
        fi
    done
fi


make_comment() {
    TEMP_FILE="$(mktemp)"
    export TEMP_FILE

    printf '%s\n\n_note: this was generated by a bot_' "$1" \
        | jq '{"body":.}' --raw-input --slurp --compact-output --exit-status \
    > "${TEMP_FILE}"

    curl \
        --request POST \
        --header "Accept: application/vnd.github.v3+json" \
        --user "${GITHUB_TOKEN_USER}:${GITHUB_TOKEN}" \
        --data "@${TEMP_FILE}" \
        --url "${PULL_REQUEST_COMMENTS_URL}/comments"

    rm "${TEMP_FILE}"
}

STANDARD_POSTSCRIPT='If you have visited the above link before, you may have to refresh your browser to see the changes. This is due to browsers caching data from websites. [This link has more information about this](https://refreshyourcache.com/en/cache/).

If the preview looks fine, the pull request can be merged.

For the reviewer, please perform a more rigorous review if this pull request modified files outside the `content/` directory.'

case "${DISPATCH_RESULT}" in
    "dispatch_timeout")
        COMMENT_BODY="$(printf \
'')"
        ;;

    "queue_timeout")
        COMMENT_BODY="$(printf \
'The preview is still waiting to be built.

GitHub Actions may be busy.

[The status of the GitHub Actions run is available here.](%s)

[The preview may become available here.](%s)

%s' "${RUN_DETAILS_URL}" "${PREVIEW_URL}" "${STANDARD_POSTSCRIPT}")"
        ;;

    "run_timeout")
        COMMENT_BODY="$(printf \
'The preview is taking an unusually long time to build.

[The status of the GitHub Actions run is available here.](%s)

[The preview may become available here.](%s)

%s' "${RUN_DETAILS_URL}" "${PREVIEW_URL}" "${STANDARD_POSTSCRIPT}")"
        ;;

    "run_error")
        COMMENT_BODY="$(printf \
'The preview was not built.

GitHub Actions may have experienced an error.

[Logs are available here.](%s)

If this was caused by a transient error, close the pull request. Then open the pull request. This will cause another preview to be built.' "${RUN_DETAILS_URL}")"
        ;;

    "run_failed")
        COMMENT_BODY="$(printf \
'There was an error building the website.

[logs are available here](%s)' "${RUN_DETAILS_URL}")"
        ;;

    "deploy_timeout")
        COMMENT_BODY="$(printf \
'GitHub pages is taking unusually long to display the preview.

[The status of the deployment is available here.](%s)

[The preview may be available here.](%s)

%s' "${DEPLOYMENT_URL}" "${PREVIEW_URL}" "${STANDARD_POSTSCRIPT}")"
        ;;

    "all_success")
        COMMENT_BODY="$(printf \
'A preview of this pull request was successfully built.

[The preview is available here.](%s)

%s' "${PREVIEW_URL}" "${STANDARD_POSTSCRIPT}")"
        ;;

    *)
        COMMENT_BODY="$(printf \
'There was an error with the dispatch or build workflow.

[dispatch workflow logs](%s)

[build workflow logs](%s)

[deployment status](%s)' "${DISPATCH_DETAILS_URL}" "${RUN_DETAILS_URL}" "${DEPLOYMENT_URL}")"
        ;;
esac

make_comment "${COMMENT_BODY}"

case "${DISPATCH_RESULT}" in
    "all_success") exit 0;;
# Setting an exit status of 1 ensures the workflow run is marked as a failure.
# This should show as a failed "check" in the GitHub UI for merging a pull
# request.
    *) exit 1;;
esac