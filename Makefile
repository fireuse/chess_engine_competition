IMAGE        ?= chess-engine:latest
ADAPTER      := ./engine-adapter.sh
CUTECHESS    ?= cutechess-cli

.PHONY: build test-uci test-game shell clean help

help:
	@echo ""
	@echo "  make build          Build the Docker image"
	@echo "  make test-uci       Smoke-test: send 'uci' to the engine"
	@echo "  make test-game      Play a 10-move game against itself via cutechess-cli"
	@echo "  make shell          Open a shell inside the container"
	@echo "  make clean          Remove the Docker image"
	@echo ""

build:
	docker build -t $(IMAGE) .

test-uci: build
	@echo "--- UCI handshake test ---"
	@printf "uci\nquit\n" | docker run --rm -i $(IMAGE) \
	    | grep -q "uciok" \
	    && echo "PASS: engine responded with uciok" \
	    || (echo "FAIL: no uciok"; exit 1)

test-game: build
	@echo "--- Self-play smoke test ---"
	@chmod +x $(ADAPTER)
	ENGINE_IMAGE=$(IMAGE) $(CUTECHESS) \
	    -engine cmd=$(ADAPTER) name=Engine1 proto=uci \
	    -engine cmd=$(ADAPTER) name=Engine2 proto=uci \
	    -each tc=40/60 \
	    -games 1 \
	    -rounds 1 \
	    -pgnout /tmp/test_game.pgn \
	    -recover \
	    -repeat \
	    && echo "PASS: game finished" && cat /tmp/test_game.pgn \
	    || echo "FAIL: cutechess returned non-zero"

shell: build
	docker run --rm -it --entrypoint /bin/bash $(IMAGE)

clean:
	docker rmi -f $(IMAGE) 2>/dev/null || true
