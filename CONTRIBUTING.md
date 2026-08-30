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

## Releasing

- Merging to `main` with changes under `.devcontainer/**` triggers
  `build-publish.yml`, which builds and pushes `ghcr.io/jonzakaras/alab-desktop:latest`
  plus a `sha-<short>` tag.
- Pushing a `v*` git tag (e.g. `v1.2.3`) additionally publishes semver tags
  (`1.2.3`, `1.2`, `1`) so consuming repos can pin to a stable version instead
  of always tracking `latest`.

## Adding a new AI CLI

See [`docs/adding-a-new-ai-cli.md`](docs/adding-a-new-ai-cli.md) for the exact
set of files to touch when adding Codex or another AI CLI alongside Claude Code.
