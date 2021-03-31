#!/bin/sh
set -eu
# To use this script, the following environment variables must be set
# - GITHUB_TOKEN
# A token with push access to the gh-pages branch of the repository that hosts
# the previews.
# The token can be found in the "github" context at "github.token".
# pull_request_target:
# https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request_target
# The github context for GitHub Actions workflows:
# https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context
#
# Additionally, these can be overridden by setting them in the calling
# environment
#
if [ -z "${GITHUB_TOKEN:+"unset"}" ]; then
    echo "GITHUB_TOKEN not set"
fi
# The name of the user that will be listed as the committer of the changes to
# the website's repository
GIT_USER_NAME="${GIT_USER_NAME:-"github-actions"}"
export GIT_USER_NAME
# The email for GIT_USER_NAME
GIT_USER_EMAIL="${GIT_USER_EMAIL:-"41898282+github-actions[bot]@users.noreply.github.com"}"
export GIT_USER_EMAIL
# The username/repository of repository that has the pull request that should
# be rendered
REPOSITORY_OF_PULL_REQUEST="${REPOSITORY_OF_PULL_REQUEST:-"mawillcockson/TXButterflies.github.io"}"
export REPOSITORY_OF_PULL_REQUEST
# Set by GitHub on its runners
# See:
# https://docs.github.com/en/actions/reference/environment-variables
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-"$(mktemp -d)"}"
export GITHUB_WORKSPACE
# The pull request number in REPOSITORY_OF_PULL_REQUEST that should be rendered
PULL_REQUEST_ID="${PULL_REQUEST_ID:-"1"}"
export PULL_REQUEST_ID
# The full payload of the github event
# Pull Request payload example:
# https://docs.github.com/en/developers/webhooks-and-events/webhook-events-and-payloads#workflow_dispatch
GITHUB_EVENT="${GITHUB_EVENT:-"$(jq --null-input --compact-output '{
    "inputs": {
        "pull_request_id": (env.PULL_REQUEST_ID),
        "pull_request_event": ({
            "action": "opened",
            "number": (env.PULL_REQUEST_ID),
            "pull_request": {
                "html_url": ("https://github.com/mawillcockson/TXButterflies.github.io/pull/" + env.PULL_REQUEST_ID),
            }
        } | @json),
    },
}')"}"
export GITHUB_EVENT
# Path to the hugo binary executable
# This should be the extended version of hugo that includes SASS/SCSS support
HUGO_BIN="${HUGO_BIN:-"$(which hugo)"}"
export HUGO_BIN
# The environment hugo should use when building the preview website
HUGO_ENVIRONMENT="${HUGO_ENVIRONMENT:-"development"}"
export HUGO_ENVIRONMENT
# The repository where the rendered website preview should be pushed to
GH_PAGES_REPOSITORY="${GH_PAGES_REPOSITORY:-"mawillcockson/pr.texasbutterfliesmonitoring.org"}"
export GH_PAGES_REPOSITORY


GITHUB_TOKEN_USER="${GITHUB_TOKEN_USER:-"github-actions"}"
export GITHUB_TOKEN_USER
SOURCE_DIR="${GITHUB_WORKSPACE}/pull_request"
export SOURCE_DIR
mkdir -p "${SOURCE_DIR}"
GH_PAGES_DIR="${GH_PAGES_DIR:-"${GITHUB_WORKSPACE}/gh-pages"}"
export GH_PAGES_DIR
DESTINATION_DIR="${GH_PAGES_DIR}/${PULL_REQUEST_ID}"
export DESTINATION_DIR

git clone \
    --depth 1 \
    --branch gh-pages \
    --single-branch \
    "https://github.com/${GH_PAGES_REPOSITORY}.git" \
    "${GH_PAGES_DIR}"

cd "${SOURCE_DIR}"
git init
git remote add origin "https://github.com/${REPOSITORY_OF_PULL_REQUEST}.git"
git fetch origin "refs/pull/${PULL_REQUEST_ID}/merge"
git checkout FETCH_HEAD
# Add pull_request event payload to the data dir so that hugo can access it
if printf '%s' "${GITHUB_EVENT}" | jq -e '.inputs | has("pull_request_event")' > /dev/null 2>&1; then
    mkdir -p ./data/
    printf '%s' "${GITHUB_EVENT}" | jq --compact-output '.inputs.pull_request_event | fromjson' > ./data/pull_request.json
fi
cd "${GITHUB_WORKSPACE}"
"${HUGO_BIN}" env --source "${SOURCE_DIR}"
"${HUGO_BIN}" config --source "${SOURCE_DIR}"
mkdir -p "${DESTINATION_DIR}"
"${HUGO_BIN}" \
    --source "${SOURCE_DIR}" \
    --destination "${DESTINATION_DIR}" \
    --cleanDestinationDir
cd "${GH_PAGES_DIR}"
git config --local user.name "${GIT_USER_NAME}"
git config --local user.email "${GIT_USER_EMAIL}"
git config --local push.default simple
git config --local push.gpgsign false
git config --local commit.gpgsign false
git add -A :/
git commit -m "publish ${REPOSITORY_OF_PULL_REQUEST}#${PULL_REQUEST_ID}"
git config --local credential.helper "store --file=\"${GITHUB_WORKSPACE}/.git-credentials\""
# From:
# https://git-scm.com/docs/git-credential-store#_storage_format
printf 'https://%s:%s@github.com' "${GITHUB_TOKEN_USER}" "${GITHUB_TOKEN}" > "${GITHUB_WORKSPACE}/.git-credentials"
git push
