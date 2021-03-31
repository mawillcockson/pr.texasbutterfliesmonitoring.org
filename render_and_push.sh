#!/bin/sh
# To use this script, the following environment variables must be set
# - GIT_USER_NAME
# The name of the user that will be listed as the committer of the changes to
# the website's repository
#
# - GIT_USER_EMAIL
# The email for GIT_USER_NAME
#
# - REPOSITORY_OF_PULL_REQUEST
# The repository that has the pull request that should be rendered
#
# - PULL_REQUEST_ID
# The pull request number in REPOSITORY_OF_PULL_REQUEST that should be rendered
#
# - GITHUB_EVENT_PATH
# The path to the full payload of the GitHub event that triggered this workflow
#
# - DESTINATION
# The directory hugo should put the rendered website files into
#
# - HUGO_BIN
# Path to the hugo binary executable
# This should be the extended version of hugo that includes SASS/SCSS support
#
# - SOURCE
# The path to the repository where this script downloaded the pull request files
#
# - REPOSITORY_OF_PULL_REQUEST
# The repository that the pull request is in
#
# - HUGO_BASEURL
# The url hugo should treat as the root of the website:
# https://gohugo.io/getting-started/configuration/#all-configuration-settings
#
# - HUGO_ENVIRONMENT
# The environment hugo should use when building the preview website
set -eu
RENDER_DIR="${GITHUB_WORKSPACE:-"$(mktemp -d)"}/pull_request"
export RENDER_DIR

git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git init "${RENDER_DIR}"
cd "${RENDER_DIR}"
git remote add origin "https://github.com/${REPOSITORY_OF_PULL_REQUEST}.git"
git fetch origin "refs/pull/${PULL_REQUEST_ID}/merge"
git checkout FETCH_HEAD
# Add pull_request event payload to the data dir so that hugo can access it
if cat "${GITHUB_EVENT_PATH}" | jq -e '.inputs | has("pull_request_event")' > /dev/null 2>&1; then
    mkdir -p ./data/
    cat "${GITHUB_EVENT_PATH}" | jq --compact-output '.inputs.pull_request_event | fromjson' > ./data/pull_request.json
fi
cd "${GITHUB_WORKSPACE}"
mkdir -p "${DESTINATION}"
"${HUGO_BIN}" env --source "${SOURCE}"
"${HUGO_BIN}" config --source "${SOURCE}"
"${HUGO_BIN}" \
    --source "${SOURCE}" \
    --destination "${DESTINATION}" \
    --cleanDestinationDir
cd "${GITHUB_WORKSPACE}/gh-pages/"
git add -A :/
git commit -m "publish ${REPOSITORY_OF_PULL_REQUEST}#${PULL_REQUEST_ID}"
git push
