#!/usr/bin/env bash
    log "Updating UID=${uid} GID=${gid}"

    if getent group napcat >/dev/null 2>&1; then
        groupmod -o -g "$gid" napcat || true
    fi

    if id napcat >/dev/null 2>&1; then
        usermod -o -u "$uid" -g "$gid" napcat || true
    fi

    chown -R "$uid:$gid" "$APP_DIR"
}

start_xvfb() {
    log "Starting Xvfb..."

    gosu napcat Xvfb :1 \
        -screen 0 1280x720x24 \
        +extension GLX \
        +render \
        -noreset \
        >/tmp/xvfb.log 2>&1 &

    sleep 2
}

start_qq() {
    export DISPLAY=:1
    export FFMPEG_PATH=/usr/bin/ffmpeg

    cd "$NAPCAT_DIR"

    log "Starting QQ..."

    if [ -n "${ACCOUNT:-}" ]; then
        exec gosu napcat /opt/QQ/qq \
            --no-sandbox \
            -q "$ACCOUNT"
    else
        exec gosu napcat /opt/QQ/qq \
            --no-sandbox
    fi
}

main() {
    log "NapCat container starting..."

    install_napcat
    init_config
    configure_webui
    apply_mode
    cleanup_runtime
    fix_permissions
    start_xvfb
    start_qq
}

main "$@"
