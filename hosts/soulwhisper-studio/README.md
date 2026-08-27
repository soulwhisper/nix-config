# soulwhisper-studio — Mac Studio inference appliance

Mac Studio · M5 Max · 64GB unified memory · 1TB SSD · 10GbE.
Purchased at the 2026-08-25 Apple event; pre-order 08-27, ships 09-22.
Key spec: 18C CPU / 40C GPU (Neural Accelerator per GPU core) / **614 GB/s**
memory bandwidth (40C GPU config only; the 32C base is 460 GB/s — must select
40C at purchase).

## Management split

| Layer | Managed by | Notes |
| --- | --- | --- |
| System config (launchd, pmset, shell, tools, brew declarations) | nix-darwin (`hosts/soulwhisper-studio`) | `just darwin switch soulwhisper-studio` |
| oMLX server + models | Homebrew (`jundot/omlx/omlx`) | ~45GB of weights live in `~/.omlx/models`, outside any package manager |
| Menu-bar app | one-time manual DMG install | brew formula ships CLI only |
| JoyAI MLX rewrite (vllm-omni adapter, streaming pipeline, AdaCodec streaming TTS, LiveKit replacement) | `uv` python env | pip/uv dev work; nixpkgs darwin python-ML is fragile, do not package |

NixOS is not an option on this machine: MLX depends on macOS Metal/GPU
drivers; Asahi support for M5 Max is years away.

## Memory budget

64GB total. `iogpu.wired_limit_mb=57344` (56GB) is applied at boot by the
`iogpu-wired-limit` launchd daemon declared in `default.nix` (sysctl does not
survive reboot). Residency group ≈ **40GB incl. system ≤ 56GB wired, ~17GB
headroom**. Only mutex pair: creative-writing ↔ vision (swap on demand);
night-exclusive lanes run on a schedule. No hard blockers at 64GB — do not
upgrade RAM.

**Precision warning**: all occupancy figures below are post-quantization. Any
resident component falling back to default bf16 loading inflates the resident
group to 48GB+ and eats the entire switch headroom. Quantized formats are a
deployment constraint, not an option.

## Resident coexisting group (~32GB models + 7GB system)

| Role | Model | Params/Quant | GB | Notes |
| --- | --- | --- | --- | --- |
| Main brain: semantic analysis, KB QA, chat, rerank | Qwen3.8-27B | 27.8B / MLX 4bit | 16.1 | Beats Qwen3.6-35B-A3B on all 8 shared benchmarks; MTP draft head ~0.2GB enabled; RAG top-15~20 candidates self-filtered in-context; expected decode ~26–30 tok/s on M5 Max (TBD); KV Q4 64K; candidate: orcarouter/Qwen3.8-27B-Uncensored-MLX |
| Throughput: batch/automation/App-Copilot | Qwen3.5-4B | 4B / MLX 4bit | 3.03 | Replaces the MoE lane: decode on par with 3–4B-active MoE (~100 tok/s) but resident, killing lane mutex; schema-constrained output + non-thinking mode; escalate low-confidence to 27B |
| TTS / voice clone | VoxCPM2 | 2B / MLX 4bit | 2.3 | Zero-shot clone SOTA at release; 48kHz, 30 languages; official bf16 pipeline needs ~8GB — must stay 4bit; native MLX inference avoids MPS op fallback |
| STT | Qwen3-ASR-1.7B | 1.7B / MLX 4bit | 2.23 | 30 languages + 22 Chinese dialects; Fleurs WER 4.9% is a 12-language subset (full 30: 12.60); native streaming/offline unified; all audio traffic goes direct to ASR, never through LLM native audio; aufklarer/Qwen3-ASR-1.7B-MLX-4bit |
| Embedding (RAG recall + offline clustering fallback) | Qwen3-Embedding-4B | 4B / MLX 4bit | 2.26 | bf16 is ~8GB — must lock 4bit; A/B against 0.6B before bulk ingest (0.6B more likely to win now that clustering moved to BM25) |
| Vision streaming | JoyAI-VL-Interaction (MLX port) | 8B / MLX 4bit | 5.76 | Hard requirement, resident; camera sessions/stream understanding; oMLX 0.5.3 supports this arch natively (M4/24GB measured TG 20–22 tok/s, PP 215–227, 4× concurrent 64.9 tok/s; M5 Max bandwidth-scaled expectation TG 60–90); xiaowangzhixiao/JoyAI-VL-Interaction-MLX-4bit |
| System + runtime | macOS 27 | — | 7 | no swap |

## On-demand lanes (swap in, not resident)

| Role | Model | Params/Quant | GB | Notes |
| --- | --- | --- | --- | --- |
| Creative writing / RP | Gemma4-31B | 31B / MLX 4bit | 18.4 | SillyTavern-style sessions; replaces main brain on demand; KV Q4 64K; native audio |
| Image generation | Z-image-turbo | 6B / MLX 4bit | 5.9 | Photorealistic |
| Music generation | ACE-Step 1.5 | 2B / MLX 4bit | 12.6 | ACE Studio, vocals + full instrumental, 19 languages, voice clone/lyric editing; alt: Magenta RealTime / MiniMax Music 3 4bit 9.2GB |

## Removed from the stack

| Removed | Former role | Disposition |
| --- | --- | --- |
| Laguna-S-2.1-118B-A8B | coding / opsec fallback | Coding assist is droppable; opsec coding falls back to the 27B local brain (data never leaves the machine), accepting quality loss |
| Gemma4-26B-A4B / Qwen3.6-35B-A3B (candidates) | batch/automation lane | Task profile (semantic analysis/clustering/dedup, no multimodal) doesn't need a flagship MoE; shrunk to resident Qwen3.5-4B |
| gemma-e4b | in-app Copilot | Audio goes direct to ASR (dialect/accuracy strictly better); quick answers moved to Qwen3.5-4B (same speed class) |
| Qwen3-Reranker-0.6B | KB rerank | Limited gain with small corpus + strong brain; 27B in-context self-filtering instead; Hermes memory retrieval uses hybrid ranking (vector + recency/frequency/metadata). Reversible: re-add (0.5GB) if corpus >500k chunks or cross-domain queries grow |
| MiniMax-H3 | video generation | 4bit undeployable locally; API ≈ ¥170/min of finished video; only localizes if demand becomes weekly |
| — | image generation API fallback | qwen-image-3.0-Pro API: ¥0.25/image @1K, ¥0.5/image @2K |

## JoyAI transcription to MLX — approved project

Model path verified (Preview 8.8B is Qwen3-VL architecture; mlx-vlm 4bit runs
on Apple Silicon). The rewrite effort concentrates in the streaming pipeline:
vllm-omni adapter layer, streaming inference loop, AdaCodec streaming TTS,
LiveKit replacement. The official sub-500ms interaction figure is a design
target of the vLLM-Omni + LiveKit (CUDA-oriented) stack — relax expectations
on the MLX side.

## oMLX operations

```bash
omlx start|stop|restart          # delegates to brew services
brew services info omlx          # status
# service log: $(brew --prefix)/var/log/omlx.log
# server log:  ~/.omlx/logs/server.log
# models:      ~/.omlx/models    (OMLX_MODEL_DIR to override)
# port:        8000              (OMLX_PORT to override)
```

Optional MCP support: `/opt/homebrew/opt/omlx/libexec/bin/pip install mcp`.
