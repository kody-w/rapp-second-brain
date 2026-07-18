#!/bin/bash
# crawl-public.sh — Phase 1 discovery for the PUBLIC hemisphere ONLY.
# Inventories every public kody-w repo, marks which are rapp-* estate, and
# seeds brain/inventory.json + brain/INDEX.md. Reads ONLY public metadata —
# it never opens a private repo's contents. Opus extends this into full
# per-node carding (Phase 2) and the freshness loop (Phase 4).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
BRAIN="$HERE/brain"; mkdir -p "$BRAIN/cards"

echo "[crawl] inventorying public kody-w repos…"
gh repo list kody-w --limit 500 --no-archived \
  --json name,visibility,description,pushedAt,url,isFork \
  --jq '[.[] | select(.visibility=="PUBLIC")]' > "$BRAIN/inventory.json"

TOTAL=$(python3 -c "import json;print(len(json.load(open('$BRAIN/inventory.json'))))")
RAPP=$(python3 -c "import json;print(sum(1 for r in json.load(open('$BRAIN/inventory.json')) if r['name'].startswith('rapp') or r['name'] in ('RAPP','RAR')))")
echo "[crawl] $TOTAL public repos, ~$RAPP in the rapp estate"

python3 - "$BRAIN" <<'PY'
import json, sys
brain = sys.argv[1]
inv = json.load(open(f"{brain}/inventory.json"))
def cls(n):
    if n == "rapp-installer": return "kernel"
    if n in ("rapp-canary","rapp-nightly","rapp-alpha","rapp-beta"): return "ring"
    if n in ("RAPP",): return "distro"
    if n.startswith("rapp-holo") or n in ("rapp-frame-net","rapp-spine"): return "spec"
    if n in ("rapp-train","rapp-tower","rapp-second-brain"): return "brain/deck"
    if n.startswith("rapp") or n in ("RAR",): return "tool/app"
    return "adjacent"
rows = sorted(inv, key=lambda r: (cls(r['name']), r['name'].lower()))
with open(f"{brain}/INDEX.md","w") as f:
    f.write("# Public brain — repo index (Phase 1 seed)\n\n")
    f.write(f"{len(inv)} public kody-w repos. Full cards land in `cards/` as Phase 2 runs.\n\n")
    f.write("| repo | class | pushed | what |\n|---|---|---|---|\n")
    for r in rows:
        d = (r.get('description') or '').replace('|','/')[:80]
        f.write(f"| [{r['name']}]({r['url']}) | {cls(r['name'])} | {r['pushedAt'][:10]} | {d} |\n")
print(f"[crawl] wrote {brain}/INDEX.md")
PY

echo "[crawl] Phase 1 seed complete. Next: Phase 2 deep-carding (see OPUS-HANDOFF.md)."
