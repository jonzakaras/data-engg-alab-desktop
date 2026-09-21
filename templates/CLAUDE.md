# Project guidance for Claude Code

<!--
  Copy this to your repo root and add your own project-specific guidance
  below. The dbt CLI section exists because this repo runs in the
  alab-desktop devcontainer, whose dbt binary layout differs from the
  defaults dbt Labs' vendored agent skills assume — see
  .claude/skills/VENDORED.md.
-->

## dbt CLI flavors in this container

This project runs in the
[alab-desktop](https://github.com/jonzakaras/data-engg-alab-desktop)
devcontainer, which ships two dbt binaries. Don't ask which flavor to use —
it's fixed:

| Flavor | Path | Invoke as |
|---|---|---|
| dbt Cloud CLI | `/usr/local/bin/dbt` | `dbt` |
| dbt Fusion | `/home/vscode/.local/share/dbt-fusion/bin/dbt` | `dbtf` |
| dbt Core | not installed | — |

- **`dbt` is the default for day-to-day work** — running models, tests,
  builds. It authenticates to dbt Platform via `~/.dbt/dbt_cloud.yml`.
- **`dbtf` (Fusion) is what the dbt VS Code extension's LSP uses.** Reach for
  it for faster parsing and stronger SQL comprehension, but treat `dbt` as the
  source of truth for anything that actually runs against the warehouse.
- `pip show dbt-core` will find nothing here. That's expected, not a broken
  install.
