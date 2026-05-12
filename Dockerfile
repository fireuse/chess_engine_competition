FROM nvidia/cuda:12.3.1-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/engines

RUN git clone --depth 1 https://github.com/alcides-schulz/Tucano.git tucano \
    && cd tucano \
    && make \
    && ls -lh tucano 2>/dev/null || ls -lh Tucano 2>/dev/null

RUN find /opt/engines/tucano -maxdepth 1 -type f -perm /111 \
        ! -name "*.cpp" ! -name "*.h" ! -name "Makefile" \
    | head -1 \
    | xargs -I{} cp {} /usr/local/bin/engine

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD echo "uci" | timeout 5 /usr/local/bin/engine | grep -q "uciok"

ENTRYPOINT ["/usr/local/bin/engine"]
