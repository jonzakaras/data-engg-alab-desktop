# Vendored: dbt Labs Agent Skills

These skills are copied verbatim from dbt Labs' official collection. They are
**not** installed through the Claude Code plugin/marketplace system, which is
blocked on ASU Claude accounts — a skill is just a directory containing a
`SKILL.md`, and Claude Code discovers those from `.claude/skills/` with no
plugin machinery involved.

| | |
|---|---|
| Upstream | https://github.com/dbt-labs/dbt-agent-skills |
| Pinned commit | `a8607fc02a679e81a2b0fe7fcb32a7568802e16a` |
| Source path | `skills/dbt/skills/` (the `dbt` plugin) |
| Vendored on | 2026-09-21 |
| License | Apache-2.0 (see `LICENSE` alongside this file) |

Only the `dbt` plugin's skills are vendored. The upstream `dbt-migration` and
`dbt-extras` plugins are not — they're one-off migration tooling, so pull them
in deliberately if and when a migration is actually happening.

## Why vendored rather than installed

Pinning to a commit and committing the files is a *stronger* governance posture
than marketplace installation, not a workaround for it:

- The exact bytes in use are fixed at a reviewed commit, with no auto-updating
  remote fetch at runtime.
- Every future change arrives as a reviewable diff in a PR.
- The full third-party surface is auditable in-tree (see below).

## What was audited before vendoring

The vendored tree is 46 files: `SKILL.md` instructions plus yaml/json/txt/sql
reference data, and exactly **two executables**, both read-only:

- `fetching-dbt-docs/scripts/search-dbt-docs.sh` — downloads
  `docs.getdbt.com/llms-full.txt` into `${XDG_CACHE_HOME:-$HOME/.cache}/dbt-docs`
  (24h cache) and greps it with `awk`. No credentials, no writes outside cache.
- `maintaining-dbt-documentation/audit_coverage.py` — reads
  `target/manifest.json`, prints a coverage report. Python stdlib only
  (`argparse`, `json`, `os`, `sys`, `collections`); no network, no writes.

Network egress referenced anywhere in the tree is dbt Labs domains only
(`docs.getdbt.com`, `hub.getdbt.com`, `cloud.getdbt.com`, `app.state.dbt.com`)
plus `github.com` and `docs.astral.sh` in prose links.

Upstream's `evals/`, `scripts/` and `tests/` Python (23 files) is repo tooling
and is deliberately **not** vendored.

## Known deviations from the alab-desktop image

`running-dbt-commands/SKILL.md` documents where the three dbt CLI flavors
normally live, and alab-desktop does not match its assumptions. The skill says
both Fusion and dbt Cloud CLI live at `~/.local/bin/dbt`. In this image:

| Flavor | alab-desktop location | Invoke as |
|---|---|---|
| dbt Cloud CLI | `/usr/local/bin/dbt` | `dbt` |
| dbt Fusion | `/home/vscode/.local/share/dbt-fusion/bin/dbt` | `dbtf` |
| dbt Core | not installed | — |

The skills are left unmodified so upstream updates stay clean diffs. Record the
layout above in the consuming repo's `CLAUDE.md` instead, so the agent doesn't
have to ask which flavor to use. The rest of the collection already understands
the `dbt` vs `dbtf` split and the Fusion/Cloud CLI distinction.

Also note `configuring-dbt-mcp-server` overlaps with `templates/.mcp.json`,
which already points at dbt Platform's hosted endpoint. Prefer the template;
the skill's local `uvx dbt-mcp` recipes are for setups that need local-project
tools.

## Updating

```sh
SHA=<new-upstream-commit>
curl -sL "https://github.com/dbt-labs/dbt-agent-skills/archive/${SHA}.tar.gz" | tar -xz
rm -rf templates/.claude/skills/*/
cp -R "dbt-agent-skills-${SHA}/skills/dbt/skills/." templates/.claude/skills/
cp "dbt-agent-skills-${SHA}/LICENSE" templates/.claude/skills/LICENSE
```

Then update the pinned commit and date in the table above, re-check the
executable inventory in the diff, and open a PR.
