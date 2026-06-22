FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash eqemu

# Download latest Spire release for Linux amd64
RUN LATEST_URL=$(curl -s https://api.github.com/repos/EQEmu/spire/releases/latest \
    | jq -r '.assets[] | select(.name | test("linux.*amd64|spire-linux")) | .browser_download_url' \
    | head -1) \
    && echo "Downloading Spire from: $LATEST_URL" \
    && curl -L -o /usr/local/bin/spire "$LATEST_URL" \
    && chmod +x /usr/local/bin/spire

WORKDIR /home/eqemu/server

RUN chown -R eqemu:eqemu /home/eqemu

USER eqemu

EXPOSE 3010

ENTRYPOINT ["spire"]
CMD ["http:serve"]
