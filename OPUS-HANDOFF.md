# OPUS-HANDOFF — build the RAPP second brain

Fable set this up; Opus builds it. This is the baton + the plan. The goal:
a **two-hemisphere second brain** for the whole RAPP ecosystem — every node
(repo, protocol, surface, service, doc-corpus) carded, edged, and queryable,
so any person or AI orients in minutes. Known and unknown, public and
private — with the leak boundary enforced by **architecture, not care**.

## The one rule that makes this safe

**Two repos. Two crawlers. They never touch.**

- **Public hemisphere** = THIS repo (`kody-w/rapp-second-brain`, public).
  Its crawler reads ONLY public sources (public repos, Pages, published
  specs). It physically cannot open a private source.
- **Private hemisphere** = `kody-w/rapp-second-brain-private` (private).
  Its crawler reads private repos + local state (`~/.brainstem_data`, tower
  `work/`, `wildhaven-ceo`, ghost/quicksilver, MSX, etc.). Its output is
  pushed ONLY to the private repo.
- A private card MAY reference a public card by `id` (an edge). It MUST NOT
  copy a private payload into anything that lands here. Secrets/tokens are
  never ingested in either hemisphere — record a pointer ("credential lives
  in X"), never the value.
- **Belt-and-suspenders**: before every push to THIS repo, run the tower's
  `tools/guard.sh` over the diff (secret + denylist + secret-filename gate).
  A guard hit blocks the push; investigate, never override.

If you can only remember one thing: the public crawler's source allowlist is
the boundary. Build it as an explicit allowlist, not a denylist.

## Phase 0 — stand on rapp-map (don't start from zero)

`kody-w/rapp-map` already holds `estate-map.json` (85 repos, repo-level) and
`neurons.json` (630 per-file cards). That is the seed corpus. Clone it, load
both, and convert every entry into a v1 brain card (SCHEMA.md). This is the
public brain's day-one content — you are DEEPENING an existing map, not
inventing one.

## Phase 1 — discover the unknowns (loop-until-dry)

The map is ~3 weeks stale and was itself once "half the estate." Find what it
misses:

1. **Full inventory**: `gh repo list kody-w --limit 500 --json name,visibility,isArchived,pushedAt`.
   Split public/private HERE — public names → public brain, private names →
   private brain (never list private repo names in the public hemisphere).
2. **Gap set**: repos in the inventory but not in rapp-map → new cards to build.
3. **Reference crawl**: grep every card's fetched content for
   `github.com/kody-w/<repo>` and `kody-w.github.io/<repo>`. Any repo
   mentioned but not carded = a discovery → enqueue.
4. **Loop**: repeat 2–3 until two consecutive rounds surface nothing new.
   Log what each round added. Silent truncation is the enemy — if you cap,
   say so in the card provenance.

## Phase 2 — deep-card each node (parallelizable; this is a Workflow)

Per node, fetch its public surface (README, key files, Pages, CI state, spec
if any) and emit a v1 card: role, estate_class, entry_points, protocols,
edges, health, a stranger-sufficient summary, provenance (public URLs only).
Fan out — one agent per node, schema-validated output, then merge. Verify a
sample of cards against the live source (a card is a claim; exercise it).

Estate scaffolding you already know (put it in the cards, don't rediscover):
kernel = rapp-installer (grail); rings = canary/nightly/alpha/beta; distros =
RAPP + microsoft/aibast (Microsoft's distro of the Brainstem); specs =
rapp-holo, rapp-frame, rapp-hydra, rapp-spine, rappid; deck = rapp-train;
tower = rapp-tower (private); registry = RAR. The RUNBOOK, PLAYBOOK, and the
memory index at `~/.claude/projects/-Users-kodywildfeuer--brainstem-src/memory/MEMORY.md`
are the authority for relationships — read them before asserting edges.

## Phase 3 — make it a BRAIN, not a folder

The brain must be queryable, not just stored:
- `brain/graph.json` — the machine graph (nodes + typed edges).
- `brain/INDEX.md` — the human index, grouped by estate_class.
- `brain/llms.txt` — machine entry point (so any AI ingests the brain).
- **A brainstem agent** (`agents/second_brain_agent.py`, drop-in) that
  answers "what is X / what depends on Y / where does Z live" by reading the
  cards over `/chat`. This is the payoff: the ecosystem answering questions
  about itself in natural language. The private hemisphere ships the same
  agent reading the union of both card sets, but only ever runs locally.
- Optional: a static `index.html` brain-explorer on this repo's Pages.

## Phase 4 — keep it alive (the freshness loop)

A stale brain lies. Add a scheduled crawl (GitHub Actions cron in the public
repo for the public hemisphere; a local cron/agent for the private one) that
re-runs Phases 1–3 weekly, diffs against the committed brain, and commits the
delta with a changelog. Drift in the map is now visible instead of silent.

## Guardrails (do not violate)

- Public crawler: allowlist of public sources only. Never `gh api` a private
  repo from the public crawl path.
- Never push private cards, private repo names, secrets, customer data, or
  employer-seam material to THIS repo. `tools/guard.sh` runs pre-push.
- Cite provenance on every card. A brain built from unnamed sources can't be
  trusted or refreshed.
- One fine-print ™ line per generated surface (Kody canon) — never per-mention.
- Read the tower `HANDOFF-2026-07-18-fable-to-opus.md` first for live estate
  state (there is an active security context and in-flight release work that
  this crawl should reflect, not disturb).

## Definition of done

Both hemispheres crawled and carded; the gap set from Phase 1 is empty (two
dry rounds); a `second_brain_agent` answers three real questions live; the
freshness loop is scheduled; and a leak test (grep the public repo for any
private repo name / secret pattern) is clean. Cite the crawl run and card
counts — done means the brain answered, not that the folder filled.
