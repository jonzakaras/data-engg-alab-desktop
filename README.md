# data-engg-alab-desktop

A standardized VS Code [Dev Container](https://containers.dev/) image for the
data engineering team: Python 3.12, the official dbt CLI, dbt Fusion (for the
dbt VS Code extension's LSP), SQLFluff, Prettier, AWS CLI, `uv`/`uvx`
(for tools like `dbt-autofix` that expect it),
[Claude Code](https://code.claude.com/docs/en/devcontainer), and wiring for
dbt Labs' [dbt MCP server](https://github.com/dbt-labs/dbt-mcp) (opt-in per
repo — see [`templates/.mcp.json`](templates/.mcp.json)), all pinned to known-good
versions and published as a single image. Opening a project in this
container gives every engineer an identical toolchain without touching their
host machine — only repos that opt in via `.devcontainer/` are affected;
everything else on your laptop is untouched.

The image is published to GHCR at `ghcr.io/jonzakaras/alab-desktop`, as a
public package — no `docker login` is needed to pull it.

> The GHCR namespace has to match this repo's owner, because the publish
> workflows authenticate with Actions' `GITHUB_TOKEN`, which is scoped to the
> owning account. If this repo is transferred into an org, `IMAGE_NAME` in
> both workflows and the `image` in `templates/devcontainer.json` have to move
> with it.

## Using this in your own repo

1. Copy [`templates/devcontainer.json`](templates/devcontainer.json) into
   `<your-repo>/.devcontainer/devcontainer.json`, and copy
   [`templates/DESKTOP_BOOTSTRAP.md`](templates/DESKTOP_BOOTSTRAP.md) into
   your repo too — it's the copy-paste auth checklist engineers onboarding
   onto your repo will actually follow. If you want Claude Code to have dbt
   MCP tools (query models/lineage/Semantic Layer directly), also copy
   [`templates/.mcp.json`](templates/.mcp.json) into `<your-repo>/.mcp.json`.
   To give Claude Code dbt Labs' official agent skills, copy
   [`templates/.claude/`](templates/.claude/) into `<your-repo>/.claude/` and
   [`templates/CLAUDE.md`](templates/CLAUDE.md) into your repo root — see
   "dbt agent skills" below.
2. Adjust the `image` tag if you want to pin a specific version instead of
   `latest`, and set `AWS_PROFILE` to your project's value. (`.mcp.json`
   needs no edits — the dbt MCP URL is our account's, already filled in.)
3. In VS Code: **Dev Containers: Reopen in Container**.

Rolling this out to a team? See
[`docs/team-rollout.md`](docs/team-rollout.md) for sharing a VS Code Profile
and an "Open in Dev Container" badge to get as close to one-click as possible.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) with the
  [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

On Windows, use WSL2 — see the "Prerequisites" section in
[`templates/DESKTOP_BOOTSTRAP.md`](templates/DESKTOP_BOOTSTRAP.md) for setup
steps. No extra setup is needed on Mac.

### Trying this solo before rolling out to a team

You don't need anyone else's buy-in to try this out. Publishing/building the
image ahead of a wider rollout isn't risky — every change to `.devcontainer/**`
is already validated by CI (hadolint + a `devcontainer build` smoke test)
before it merges.

The image is public, so there's nothing to authenticate against GHCR — a
`docker pull` (or "Reopen in Container") works straight away. If you ever flip
the package to private under your account's Packages settings, every consumer
then needs a one-time `docker login`, using a token that carries the
`read:packages` scope (a plain `gh auth login` token does **not** have it):

```sh
gh auth refresh -h github.com -s read:packages
gh auth token | docker login ghcr.io -u <your-github-username> --password-stdin
```

To trial this in one of your own repos without affecting anyone else who has
that repo cloned: copy `templates/devcontainer.json` into
`<your-repo>/.devcontainer/devcontainer.json` as usual, but instead of
`git add`-ing it, add `.devcontainer/` to that repo's `.git/info/exclude` (a
local-only ignore file — never committed, never pushed). The container works
exactly the same for you; nobody else sees the file until you're ready. Once
you're satisfied, remove the exclude entry and commit `.devcontainer/` for
real — that's the point it becomes visible (as an optional "Reopen in
Container" prompt, never forced) to the rest of the repo's collaborators.

### First-run authentication

No credentials are baked into the image — each developer authenticates
individually once the container is running. A `bootstrap.sh` script runs
automatically on container creation and reports what's missing. For the full
copy-paste version of this checklist (meant to be copied into a consuming
repo for its own engineers), see
[`templates/DESKTOP_BOOTSTRAP.md`](templates/DESKTOP_BOOTSTRAP.md); the short
version:

| Credential | How |
|---|---|
| AWS | `aws sso login --profile <name>`, or bind-mount `~/.aws` from your host in your repo's `devcontainer.json` |
| GitHub | `gh auth login` in the container terminal, or use VS Code's built-in GitHub auth |
| dbt Platform | Download `dbt_cloud.yml` from dbt Platform (Account settings > Your profile > VS Code Extension > Download credentials) into `~/.dbt/` on your host, and bind-mount `~/.dbt` in your repo's `devcontainer.json` (see template) |
| Claude Code | Run `claude` in the container terminal and follow the sign-in prompt. Your session persists across rebuilds. |
| dbt MCP (optional) | Nothing to configure — `.mcp.json` already points at our hosted endpoint. Approve the `dbt` MCP server the first time `claude` loads it, then sign in via the browser prompt on first use (OAuth, no token). See DESKTOP_BOOTSTRAP.md. |

### Two dbt tools, on purpose

`dbt` on PATH is the official dbt CLI (self-identifies as "dbt Cloud CLI") —
use it for day-to-day `dbt build`/`debug`/`run` against dbt Platform. A
second, separate engine, **dbt Fusion**, is also installed — it's the only
engine the `dbtLabsInc.dbt` VS Code extension's LSP (autocomplete, live SQL
preview, error highlighting) actually talks to; dbt Cloud CLI and dbt-core
aren't. They're designed to coexist, not replace one another:

- `dbt` keeps resolving to dbt Cloud CLI in the terminal.
- `dbtf` (a shell alias, terminal-only) invokes Fusion directly.
- The VS Code extension doesn't see shell aliases — it's pointed at Fusion's
  actual binary via the `dbt.dbtPath` setting in `devcontainer.json`.

Fusion is pre-1.0 (pinned to the `stable` release channel, not an exact
version) and Redshift support in Fusion itself is "Preview" as of writing —
treat `dbtf` as powering editor features, not as a warehouse-execution
guarantee. Day-to-day runs should go through `dbt`.

### dbt agent skills

[`templates/.claude/skills/`](templates/.claude/skills/) carries dbt Labs'
official [dbt agent skills](https://github.com/dbt-labs/dbt-agent-skills)
(Apache-2.0) — model building, unit tests, documentation, Semantic Layer,
Mesh, job troubleshooting. Copy the directory into a consuming repo's
`.claude/` and Claude Code picks the skills up automatically.

They're **vendored, not installed via `/plugin`**: the Claude Code plugin
marketplace is blocked on ASU accounts. A skill is just a directory with a
`SKILL.md`, so the plugin system isn't needed to use one. Pinning to a
reviewed upstream commit is also the stronger posture — fixed bytes, no
auto-updating remote fetch, and every change arrives as a PR diff.

[`templates/.claude/skills/VENDORED.md`](templates/.claude/skills/VENDORED.md)
records the pinned commit, the pre-vendoring audit (46 files, only two
executables, both read-only), and the update procedure.

One deviation worth knowing: the skills' `running-dbt-commands` assumes the
conventional dbt binary paths, which aren't this image's (see "Two dbt tools,
on purpose" above). Rather than patch the skills and make future updates
conflict, [`templates/CLAUDE.md`](templates/CLAUDE.md) states the real layout
— copy it into the consuming repo's root alongside the skills.

## Repo layout

```
.devcontainer/
  Dockerfile              the image definition, built + published to GHCR
  devcontainer.json        this repo's own dev container (dogfoods the image)
  managed-settings.json     baseline Claude Code org policy
  bootstrap.sh              first-run tool/auth check (postCreateCommand)
  bash-prompt.sh            branch-aware "alab-desktop (branch) $" shell prompt
  init-firewall.sh          optional network-egress hardening, not enabled by default
templates/
  devcontainer.json         snippet other repos copy into their own .devcontainer/
  DESKTOP_BOOTSTRAP.md      copy-paste auth checklist for engineers onboarding onto a consuming repo
  .mcp.json                 optional dbt MCP server config, copied to a consuming repo's own root
  CLAUDE.md                 project guidance stating this image's dbt binary layout
  .claude/skills/           vendored dbt Labs agent skills (pinned; see VENDORED.md)
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
