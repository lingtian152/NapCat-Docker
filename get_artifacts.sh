#!/usr/bin/env bash

set -Eeuo pipefail

TOKEN="$1"
VERSION="$2"

OUTPUT_DIR="."
OUTPUT_FILE="${OUTPUT_DIR}/NapCat.Shell.zip"

log() {
    echo "[$(date '+%F %T')] $*"
}

error() {
    echo "[ERROR] $*" >&2
    exit 1
}

check_args() {
    [ -z "$VERSION" ] && error "Usage: $0 <github_token> <version>"

    if [ -z "$TOKEN" ]; then
        log "No GitHub token provided, using anonymous download"
    fi
}

download_release() {
    local url="https://github.com/NapNeko/NapCatQQ/releases/download/$VERSION/NapCat.Shell.zip"

    log "Downloading NapCat release..."
    log "Version: ${VERSION}"

    local curl_args=(
        -fL
        --retry 3
        --retry-delay 2
        --connect-timeout 15
        --max-time 300
        -A "NapCat-Downloader"
        -o "$OUTPUT_FILE"
    )

    if [ -n "$TOKEN" ]; then
        curl_args+=(
            -H "Authorization: Bearer ${TOKEN}"
        )
    fi

    curl "${curl_args[@]}" "$url"
}

verify_file() {
    if [ ! -f "$OUTPUT_FILE" ]; then
        error "Download failed: file not found"
    fi

    if [ ! -s "$OUTPUT_FILE" ]; then
        rm -f "$OUTPUT_FILE"
        error "Download failed: empty file"
    fi

    if ! unzip -tq "$OUTPUT_FILE" >/dev/null 2>&1; then
        rm -f "$OUTPUT_FILE"
        error "Invalid zip file"
    fi
}

show_result() {
    local size
    size=$(du -h "$OUTPUT_FILE" | awk '{print $1}')

    log "Download completed"
    log "File: $OUTPUT_FILE"
    log "Size: $size"
}

main() {
    check_args
    download_release
    verify_file
    show_result
}

main "$@"
