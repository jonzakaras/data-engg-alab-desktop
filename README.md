# data-engg-alab-desktop

A standardized VS Code [Dev Container](https://containers.dev/) image for the
data engineering team: Python 3.12, dbt Cloud CLI, SQLFluff, Prettier, AWS CLI,
and [Claude Code](https://code.claude.com/docs/en/devcontainer), all pinned to
known-good versions and published as a single image. Opening a project in this
container gives every engineer an identical toolchain without touching their
host machine — only repos that opt in via `.devcontainer/` are affected;
everything else on your laptop is untouched.

The image is published to GHCR at `ghcr.io/jonzakaras/alab-desktop`.

## Using this in your own repo

1. Copy [`templates/devcontainer.json`](templates/devcontainer.json) into
   `<your-repo>/.devcontainer/devcontainer.json`.
2. Adjust the `image` tag if you want to pin a specific version instead of
   `latest`, and add any repo-specific `mounts`/`containerEnv` (marked in the
   template).
3. In VS Code: **Dev Containers: Reopen in Container**.

Rolling this out to a team? See
[`docs/team-rollout.md`](docs/team-rollout.md) for sharing a VS Code Profile
and an "Open in Dev Container" badge to get as close to one-click as possible.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) with the
  [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### First-run authentication

No credentials are baked into the image — each developer authenticates
individually once the container is running. A `bootstrap.sh` script runs
automatically on container creation and reports what's missing, but here's the
checklist:

| Credential | How |
|---|---|
| AWS | `aws sso login --profile <name>`, or bind-mount `~/.aws` from your host in your repo's `devcontainer.json` |
| GitHub | `gh auth login` in the container terminal, or use VS Code's built-in GitHub auth |
| dbt Cloud | Set `DBT_CLOUD_API_TOKEN` and `DBT_CLOUD_ACCOUNT_ID` in your repo's `devcontainer.json` `containerEnv` |
| Claude Code | Run `claude` in the container terminal and follow the sign-in prompt. Your session persists across rebuilds. |

## Repo layout

```
.devcontainer/
  Dockerfile              the image definition, built + published to GHCR
  devcontainer.json        this repo's own dev container (dogfoods the image)
  managed-settings.json     baseline Claude Code org policy
  bootstrap.sh              first-run tool/auth check (postCreateCommand)
  init-firewall.sh          optional network-egress hardening, not enabled by default
templates/
  devcontainer.json         snippet other repos copy into their own .devcontainer/
docs/
  adding-a-new-ai-cli.md    the recipe for adding a second AI CLI (e.g. Codex) later
```

## Adding a second AI CLI later

Claude Code ships today; the image is structured so adding another AI CLI
(e.g. Codex, once its install mechanism is known) is additive — see
[`docs/adding-a-new-ai-cli.md`](docs/adding-a-new-ai-cli.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to modify and test this image
itself.
