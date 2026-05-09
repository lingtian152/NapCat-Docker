FROM mlikiowa/napcat-docker:base

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# 创建用户
RUN useradd \
    --system \
    --create-home \
    --home-dir /app \
    --shell /usr/sbin/nologin \
    napcat

# 复制文件
COPY NapCat.Shell.zip entrypoint.sh templates /app/

# 安装 tini + QQ
RUN set -eux; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        tini; \
    \
    arch="$(dpkg --print-architecture)"; \
    \
    case "$arch" in \
        amd64) qq_arch="amd64" ;; \
        arm64) qq_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    \
    QQ_VERSION="3.2.28-48517"; \
    QQ_URL="https://dldir1v6.qq.com/qqfile/qq/QQNT/f9cbaab2/linuxqq_${QQ_VERSION}_${qq_arch}.deb"; \
    \
    echo "Downloading QQ: ${QQ_URL}"; \
    \
    for i in {1..5}; do \
        if curl \
            -fL \
            --retry 3 \
            --retry-delay 5 \
            --connect-timeout 30 \
            --max-time 300 \
            -A "NapCat-Docker" \
            -o /tmp/linuxqq.deb \
            "$QQ_URL"; then \
            break; \
        fi; \
        \
        echo "Attempt ${i} failed"; \
        sleep 10; \
    done; \
    \
    test -s /tmp/linuxqq.deb; \
    \
    dpkg -i /tmp/linuxqq.deb || apt-get install -fy; \
    \
    rm -f /tmp/linuxqq.deb; \
    \
    chmod +x /app/entrypoint.sh; \
    \
    echo "(async () => {await import('file:///app/napcat/napcat.mjs');})();" \
        > /opt/QQ/resources/app/loadNapCat.js; \
    \
    sed -i \
        's|\"main\": \"[^\"]*\"|\"main\": \"./loadNapCat.js\"|' \
        /opt/QQ/resources/app/package.json; \
    \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# 挂载目录
VOLUME ["/app/napcat/config"]
VOLUME ["/app/.config/QQ"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "/opt/QQ/qq" >/dev/null || exit 1

# 使用 tini
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["bash", "/app/entrypoint.sh"]
