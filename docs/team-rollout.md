# Team rollout: shared VS Code profile + one-click onboarding

Goal: a developer opens a subscribing repo and ends up in the standardized
container with as little manual setup as possible.

## What's actually automatic, and what isn't

VS Code has no fully-silent way to auto-launch a dev container — the first
time someone opens a repo containing `.devcontainer/`, VS Code always shows a
"Reopen in Container?" prompt. The good news: that choice is **remembered per
folder** afterward, so it's a one-click-per-repo, not something that nags on
every open. (The only truly zero-click alternative is GitHub Codespaces,
which isn't something this repo assumes — introducing it would need Codespaces
enabled/billed at the org level and its own ASU review, so it's out of scope
here.)

Two things get that one click as close to automatic as it can be:

## 1. Share a VS Code Profile

A [VS Code Profile](https://code.visualstudio.com/docs/configure/profiles)
pre-installs extensions and settings on a developer's **local** VS Code,
before they ever open a subscribing repo. It's separate from the devcontainer
itself — the devcontainer controls what's installed *inside* the container;
the profile controls the host VS Code window around it.

To create and share one:

1. Command Palette → **Profiles: Create Profile** → name it (e.g. `alab-desktop`).
2. With that profile active, install the extensions this desktop expects:
   `ms-vscode-remote.remote-containers` (Dev Containers — required to use this
   at all), plus the same list from `devcontainer.json`'s
   `customizations.vscode.extensions`: `sqlfluff.vscode-sqlfluff`,
   `ms-python.python`, `anthropic.claude-code`, `GitHub.vscode-pull-request-github`,
   `AmazonWebServices.aws-toolkit-vscode`, `esbenp.prettier-vscode`.
3. Command Palette → **Profiles: Export Profile** → export to a GitHub Gist.
4. Share the resulting `https://vscode.dev/editor/profile/github/<id>` link
   with the team. Opening it prompts each developer to import the profile
   into their own local VS Code, once.

Importing the profile does **not** open or build any container — it just
means a new developer's VS Code already has the right extensions installed
and is ready to act on the "Reopen in Container?" prompt the moment they open
a subscribing repo.

## 2. Optional: an "Open in Dev Container" badge

For a genuine single click from a completely fresh clone, subscribing repos
can add this to their own README (swap in that repo's URL):

```md
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/<org>/<repo>)
```

Clicking it installs the Dev Containers extension if needed, clones the repo
into a container volume, and opens it directly in the container — no local
`git clone` step required first.

## Does this affect the dbt platform?

No. dbt Cloud interacts with these repos through its own git integration (the
web IDE, CI jobs, deploy runs) — entirely independent of a developer's local
editor or container setup. dbt's own file scanning is limited to the paths
declared in `dbt_project.yml` (`model-paths`, `seed-paths`, etc.), so adding
`.devcontainer/` or anything else at the repo root doesn't interfere with it.
The devcontainer only changes the *local development* experience: what tools
a developer has available when editing and running `dbt-cloud-cli` commands
against the same dbt Cloud project.

## No dbt VS Code extension ships by default

The base image installs `dbt-cloud-cli` (for triggering/managing dbt Cloud
jobs remotely), not dbt Core or the dbt Fusion engine. Neither the official
`dbtLabsInc.dbt` extension (requires Fusion) nor most dbt-core-oriented
extensions work against `dbt-cloud-cli` alone, so none is bundled — shipping
one that silently doesn't function is worse than shipping none.

If a repo's local dev workflow actually runs models against the warehouse
directly (dbt Fusion or dbt Core, not just triggering Cloud jobs), add the
relevant CLI and its matching VS Code extension in **that repo's own**
`devcontainer.json` — `customizations.vscode.extensions` merges with this
image's list, so nothing here needs to change.
