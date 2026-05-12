# Chess Engine Container — cutechess-cli adapter

Reusable Docker template: CUDA-capable container whose UCI engine is callable
by [cutechess-cli](https://github.com/cutechess/cutechess) as a normal
executable.  Tucano is bundled as a test engine; swap it for your own when
ready.

---

## How it works

```
cutechess-cli
    │  exec()
    ▼
engine-adapter.sh          ← host-side shim (the "engine" binary)
    │  docker run -i
    ▼
Container (chess-engine:latest)
    │  ENTRYPOINT
    ▼
/usr/local/bin/engine      ← UCI engine inside container
    │  stdin / stdout
    └──────────────────────── UCI protocol back to cutechess
```

cutechess communicates with engines over **stdin/stdout** using UCI (or
XBoard).  The adapter is nothing more than `docker run --rm -i <image>` —
Docker passes the pipe straight through, so cutechess never knows there is a
container in the middle.

---

## Quick start

### 1. Prerequisites

| Tool | Minimum version |
|---|---|
| Docker | 20.10 |
| NVIDIA Container Toolkit | any (optional — skipped if no GPU) |
| cutechess-cli | 1.3.0 |

### 2. Build

```bash
make build
# or manually:
docker build -t chess-engine:latest .
```

### 3. Smoke-test the engine (no cutechess needed)

```bash
make test-uci
```

Expected output:
```
--- UCI handshake test ---
PASS: engine responded with uciok
```

### 4. Run a self-play game with cutechess-cli

```bash
# Make sure cutechess-cli is on PATH (or set CUTECHESS=/path/to/cutechess-cli)
make test-game
```

### 5. Use in your own cutechess-cli command

```bash
chmod +x engine-adapter.sh

cutechess-cli \
  -engine cmd=/absolute/path/to/engine-adapter.sh name=MyEngine proto=uci \
  -engine cmd=stockfish name=Stockfish proto=uci \
  -each tc=40/60 \
  -games 10
```

---

## Environment variables for the adapter

| Variable | Default | Description |
|---|---|---|
| `ENGINE_IMAGE` | `chess-engine:latest` | Docker image to run |
| `ENGINE_CMD` | *(ENTRYPOINT)* | Override container command |
| `ENGINE_GPU` | `auto` | Set `0` to disable `--gpus all` |
| `ENGINE_MEMORY` | `2g` | `--memory` limit |
| `ENGINE_CPUS` | *(none)* | `--cpus` quota |
| `ENGINE_NET` | `none` | `--network` mode |
| `ENGINE_EXTRA_ARGS` | *(none)* | Extra `docker run` flags (space-separated) |

Example — run on CPU only with 4 GB RAM:
```bash
ENGINE_IMAGE=chess-engine:latest ENGINE_GPU=0 ENGINE_MEMORY=4g \
  cutechess-cli -engine cmd=./engine-adapter.sh ...
```

---

## Swapping in your own engine

1. **Edit `Dockerfile`** — replace the Tucano build section with your engine.
2. Make sure your engine binary ends up at `/usr/local/bin/engine` (or adjust
   `ENTRYPOINT`).
3. If your engine needs CUDA at runtime keep the `devel` base image; for
   inference-only you can switch to the lighter `runtime` variant:
   ```dockerfile
   FROM nvidia/cuda:12.3.1-runtime-ubuntu22.04
   ```
4. `make build && make test-uci`

---

## File layout

```
.
├── Dockerfile          CUDA base + engine build
├── engine-adapter.sh   Host shim — the "binary" cutechess calls
├── Makefile            Build / test helpers
└── README.md           This file
```

---

## Troubleshooting

**`uciok` never arrives**
Run `make shell` and test the engine manually:
```bash
printf "uci\nquit\n" | /usr/local/bin/engine
```

**cutechess reports "engine crashed"**
Check that the adapter is executable (`chmod +x engine-adapter.sh`) and that
`docker` is on your `PATH`.

**GPU not detected**
Verify with `nvidia-smi` on the host.  The adapter falls back to CPU
automatically when no GPU is found.

**Tucano Makefile fails**
Tucano's source uses a plain `Makefile`; it needs `g++`.  If the binary ends
up named `Tucano` (capital T) the Dockerfile's `find` command will still
locate and copy it — check with `make shell` and `ls /usr/local/bin/engine`.
