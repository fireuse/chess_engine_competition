# =============================================================================
# Chess Engine Container Template — CUDA + cutechess-cli adapter
# Base image: CUDA 12 devel (swap tag to match your driver)
# =============================================================================
FROM nvidia/cuda:12.3.1-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Build Tucano (UCI engine — used here as a test engine)
# Replace this section with your CUDA engine when ready.
# ---------------------------------------------------------------------------
WORKDIR /opt/engines

RUN git clone --depth 1 https://github.com/alcides-schulz/Tucano.git tucano \
    && cd tucano/src \
    && make avx2

RUN find /opt/engines/tucano/src -type f -perm /111 \
        ! -name "*.cpp" ! -name "*.h" ! -name "Makefile" ! -name "*.o" \
    | head -1 \
    | xargs -I{} cp {} /usr/local/bin/engine

RUN wget https://raw.githubusercontent.com/alcides-schulz/TucanoNets/main/tucano_nn03.bin -O /usr/local/bin/tucano_nn03.bin


HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD echo "uci" | timeout 5 /usr/local/bin/engine | grep -q "uciok"

ENTRYPOINT ["/usr/local/bin/engine"]
