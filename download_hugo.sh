#!/bin/sh
set -eu
HUGO_DIR="${GITHUB_WORKSPACE:-"$(mktemp -d)"}/hugo"
mkdir -p "${HUGO_DIR}"
curl --fail \
    --fail-early \
    --location \
    --url 'https://api.github.com/repos/gohugoio/hugo/releases/latest' \
    --output "${HUGO_DIR}/hugo_releases.json"

# Extracts the tar file and checksums for the latest hugo release, and produces
# a file that contains lines to export that info as environment variables
# See: https://docs.github.com/en/rest/reference/repos#releases
cat "${HUGO_DIR}/hugo_releases.json" \
| jq --exit-status \
     --compact-output \
     --raw-output \
     '.assets |
        (
          map(select(.name | test("^hugo_extended_\\d+\\.\\d+\\.\\d+_Linux-64bit.tar.gz$")))[0]
          | ["HUGO_FILENAME='"'"'" + .name + "'"'"'", "HUGO_URL='"'"'" + .browser_download_url + "'"'"'"]
        )
        +
        (
          map(select(.name | test("^hugo_\\d+\\.\\d+\\.\\d+_checksums.txt$")))[0]
          | ["CHECKSUM_FILENAME='"'"'" + .name + "'"'"'", "CHECKSUM_URL='"'"'" + .browser_download_url + "'"'"'"]
        )
        | .[]' \
> "${HUGO_DIR}/environment_variables.sh"
. "${HUGO_DIR}/environment_variables.sh"

curl --fail \
     --location \
     --url "${CHECKSUM_URL}" \
     --output "${HUGO_DIR}/${CHECKSUM_FILENAME}" &
CHECKSUM_PID=$!
curl --fail \
     --location \
     --url "${HUGO_URL}" \
     --output "${HUGO_DIR}/${HUGO_FILENAME}" &
HUGO_PID=$!
wait "${CHECKSUM_PID}" "${HUGO_PID}"

cd "${HUGO_DIR}"
grep --no-messages \
    --no-filename \
    --fixed-strings \
    "${HUGO_FILENAME}" \
    "${CHECKSUM_FILENAME}" \
| sha256sum --check
cd ../

tar -vxzf "${HUGO_DIR}/${HUGO_FILENAME}" --overwrite -C "${HUGO_DIR}"

rm \
    "${HUGO_DIR}/hugo_releases.json" \
    "${HUGO_DIR}/environment_variables.sh" \
    "${HUGO_DIR}/LICENSE" \
    "${HUGO_DIR}/README.md" \
    "${HUGO_DIR}/${HUGO_FILENAME}" \
    "${HUGO_DIR}/${CHECKSUM_FILENAME}"

echo "HUGO_BIN=${HUGO_DIR}/hugo" >> "${GITHUB_ENV}"
