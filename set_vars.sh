#!/bin/sh
OLD_OPTIONS="$(set +o)"
set -eu

for var in "GITHUB_TOKEN" "GITHUB_TOKEN_USER"; do
    if [ -z "$(eval "printf '%s' \"\${${var}:-}\"")" ]; then
        printf "%s: " "${var}"
        read "${var}"
        export "${var}"
    fi
done

export RENDER_REPOSITORY_TOKEN="${GITHUB_TOKEN}"
export RENDER_REPOSITORY_TOKEN_USER="${GITHUB_TOKEN_USER}"

eval "${OLD_OPTIONS}"
set +e
