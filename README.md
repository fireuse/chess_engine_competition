# ♟️ Chess Engine Container

> Szablon kontenera Dockerowego dla silników szachowych z obsługą GPU (NVIDIA CUDA) — przygotowany dla Koła Naukowego.

---

## Opis projektu

Ten projekt to kompletny szablon kontenera Dockerowego, który pozwala uruchamiać silniki szachowe w izolowanym środowisku i komunikować się z programami sędziowskimi (np. Cute Chess) za pomocą uniwersalnego adaptera. Obsługuje akcelerację GPU przez NVIDIA CUDA.

Jako silnik testowy wykorzystany został **Tucano**, skompilowany z obsługą sieci neuronowych (NNUE).

---

## Jak to działa? (Architektura)

Większość programów sędziowskich wymaga lokalnego pliku wykonywalnego. Ten projekt rozwiązuje to za pomocą **adaptera — lekkiego skryptu po stronie hosta**, który udaje silnik:

```
Cute Chess (Sędzia)
    │  wywołuje skrypt lokalny
    ▼
engine-adapter.sh          ← Host-side shim (udaje silnik)
    │  docker run -i
    ▼
Kontener (chess-engine)    ← Izolowane środowisko
    │  ENTRYPOINT
    ▼
/usr/local/bin/engine      ← Silnik szachowy w kontenerze
    │  stdin / stdout
    └──────────────────────── Protokół UCI (przez strumienie)
```

Dzięki flagom `--interactive` i `--init` komunikacja UCI przechodzi przez kontener **przezroczyście**, a sygnały systemowe (np. zatrzymanie gry) są poprawnie przekazywane.

---

## Wymagania wstępne

| Narzędzie | Wersja | Uwagi |
|---|---|---|
| **Docker** | 20.10+ | Wymagany |
| **NVIDIA Container Toolkit** | dowolna | Opcjonalny (tylko dla GPU) |
| **Cute Chess** | CLI lub GUI | Do przeprowadzania rozgrywek |

---

## Szybki start

Wszystkie kluczowe operacje są zautomatyzowane w pliku `Makefile`.

### Budowanie obrazu

Zbuduje kontener, skompiluje silnik Tucano i pobierze wymaganą sieć neuronową:

```bash
make build
```

### Test komunikacji (Smoke-test)

Sprawdzi, czy kontener działa i czy silnik poprawnie odpowiada na komendę `uci`:

```bash
make test-uci
```

### Testowa partia (Self-play)

Uruchomi automatyczną partię (Tucano vs Tucano) za pomocą `cutechess-cli`:

```bash
make test-game
```

---

## Organizacja turnieju

### Gra między różnymi drużynami

Nie musisz kopiować adaptera dla każdego uczestnika. Możesz użyć tego samego skryptu, podając nazwę obrazu przez zmienną środowiskową:

```bash
cutechess-cli \
    -engine name="Druzyna_A" cmd="env ENGINE_IMAGE=obraz_a ./engine-adapter.sh" proto=uci \
    -engine name="Druzyna_B" cmd="env ENGINE_IMAGE=obraz_b ./engine-adapter.sh" proto=uci \
    -each tc=40/60 -games 2 -rounds 1 -pgnout wyniki.pgn
```

### Użycie w Cute Chess GUI

1. Otwórz **Cute Chess GUI**.
2. Przejdź do **Tools → Settings → Engines**.
3. Kliknij **Add** i w polu *Command* wskaż plik `engine-adapter.sh`.
4. *(Opcjonalnie)* Aby zmienić obraz w GUI, wyeksportuj zmienną `ENGINE_IMAGE` przed uruchomieniem Cute Chess w terminalu.

---

## Konfiguracja adaptera

Adapter wspiera następujące zmienne środowiskowe (ustawiane przez `env`):

| Zmienna | Domyślnie | Opis |
|---|---|---|
| `ENGINE_IMAGE` | `chess-engine:latest` | Tag obrazu Docker do uruchomienia |
| `ENGINE_GPU` | `auto` | `0` wyłącza GPU; `auto` wykrywa `nvidia-smi` na hoście |
| `ENGINE_MEMORY` | `2g` | Limit pamięci RAM dla kontenera |
| `ENGINE_CPUS` | *(brak)* | Limit rdzeni CPU (np. `1.0`) |

---

## Podmiana silnika na własny

Aby przygotować własny silnik:

1. Edytuj `Dockerfile`.
2. Zastąp sekcję `# Build Tucano` własnymi instrukcjami kompilacji.
3. Upewnij się, że finalny plik binarny znajduje się pod ścieżką `/usr/local/bin/engine` wewnątrz kontenera.
4. Zbuduj i przetestuj:

```bash
make build
make test-uci
```

---

## Pomoc techniczna

**Problem z uprawnieniami Dockera na Linuxie?** Wykonaj:

```bash
sudo usermod -aG docker $USER
```

> Wymagane wylogowanie i ponowne zalogowanie, aby zmiany weszły w życie.
