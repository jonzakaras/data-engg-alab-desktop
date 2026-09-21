# Contributing

This repo builds and publishes the `alab-desktop` image. Everything below is
about working on the image itself, not about consuming it in another repo (see
the main [README](README.md) for that).

## Local dev loop

1. Open this repo in VS Code and **Reopen in Container** — this builds
   `.devcontainer/Dockerfile` directly (not the published image), so changes
   are visible immediately on rebuild.
2. Make your change (Dockerfile, `bootstrap.sh`, `managed-settings.json`, etc.)
   and **Dev Containers: Rebuild Container** to test it.
3. Before opening a PR, validate the build the same way CI will:
   ```sh
   npm install -g @devcontainers/cli
   devcontainer build --workspace-folder .
   ```
4. Open a PR touching `.devcontainer/**`. `pr-validate.yml` runs a
   `devcontainer build` smoke test and lints the Dockerfile with hadolint
   (blocks on errors, warns on style).

## Bumping the Claude Code version

Claude Code is pinned via `ARG CLAUDE_CODE_VERSION` in
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile) rather than using the
always-latest devcontainer feature, so builds stay reproducible. To upgrade:

1. Update `CLAUDE_CODE_VERSION` in the Dockerfile.
2. Update the matching `args.CLAUDE_CODE_VERSION` in
   [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json).
3. Rebuild locally and confirm `claude --version` reports the new version.

## Bumping the dbt CLI version

The official dbt CLI ([github.com/dbt-labs/dbt-cli](https://github.com/dbt-labs/dbt-cli))
is pinned via `ARG DBT_CLI_VERSION` in
[`.devcontainer/Dockerfile`](.devcontainer/Dockerfile), downloaded directly
from GitHub releases (no devcontainer feature exists for it). To upgrade,
update `DBT_CLI_VERSION` in the Dockerfile, rebuild, and confirm
`dbt --version` reports the new version.

## Changing the dbt Fusion channel

dbt Fusion (a separate engine from the dbt CLI above — see the README's "Two
dbt tools, on purpose") has no semver release cadence yet, so it's pinned to
a named release channel via `ARG DBT_FUSION_CHANNEL` (default `stable`), not
an exact version. To pin an exact build instead, set it to a version string
like `2.0.0-preview.212` (see `https://public.cdn.getdbt.com/fs/versions.json`
for what's available). After rebuilding, confirm with
`/home/vscode/.local/share/dbt-fusion/bin/dbt --version`.

## Bumping the uv version

`uv`/`uvx` ([astral.sh/uv](https://astral.sh/uv)) is pinned via `ARG UV_VERSION`
in the Dockerfile, installed via Astral's own versioned install script
(`astral.sh/uv/<version>/install.sh`) rather than a devcontainer feature. To
upgrade, update `UV_VERSION`, rebuild, and confirm `uv --version` reports the
new version.

## Bumping the dbt MCP version

[`dbt-mcp`](https://github.com/dbt-labs/dbt-mcp) (dbt Labs' official MCP
server) is pinned via `ARG DBT_MCP_VERSION` in the Dockerfile and installed
as a `uv tool` (not the unpinned `uvx dbt-mcp` most docs show, which
re-resolves on every launch). To upgrade, update `DBT_MCP_VERSION`, rebuild,
and confirm with `dbt-mcp < /dev/null` (it has no `--version` flag; see the
comment above the matching check in `bootstrap.sh` for why stdin is closed).

Note that [`templates/.mcp.json`](templates/.mcp.json) no longer uses this
binary — it points Claude at dbt Platform's hosted MCP endpoint
(`https://it114.us1.dbt.com/api/ai/v1/mcp`) over HTTP. The local server is
still installed for repos that need its local-project tools; see the comment
above the install in the Dockerfile.

## Releasing

- Merging to `main` with changes under `.devcontainer/**` triggers
  `build-publish.yml`, which builds and pushes `ghcr.io/asu-edplus-org/alab-desktop:latest`
  plus a `sha-<short>` tag.
- Pushing a `v*` git tag (e.g. `v1.2.3`) triggers the separate
  `release-publish.yml` (not gated on `.devcontainer/**` changes, since a
  release tag is normally applied to an existing `main` commit) and publishes
  semver tags (`1.2.3`, `1.2`, `1`) so consuming repos can pin to a stable
  version instead of always tracking `latest`.

## Adding a new AI CLI

See [`docs/adding-a-new-ai-cli.md`](docs/adding-a-new-ai-cli.md) for the exact
set of files to touch when adding Codex or another AI CLI alongside Claude Code.
