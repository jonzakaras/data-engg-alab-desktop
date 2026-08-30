# alab-desktop: getting started

Copy this file into your repo alongside `devcontainer.json` (see
`templates/devcontainer.json` in
[data-engg-alab-desktop](https://github.com/jonzakaras/data-engg-alab-desktop))
so engineers onboarding onto this repo have a single copy-paste checklist.

This assumes your `devcontainer.json` mounts `~/.aws` and `~/.dbt` from your
host (the template does this by default) — nothing here is written only
inside the container and lost on rebuild; it lands on your host, where the
container just reads/writes it directly.

## 1. Prerequisites (one-time, per machine)

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) with the
  [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## 2. Open the repo in the container

Clone this repo, open it in VS Code, then Command Palette →
**Dev Containers: Reopen in Container**. First build takes a few minutes;
after that it's cached.

A `bootstrap.sh` script runs automatically and prints a PASS/WARN/FAIL table.
FAIL means the image itself is broken — stop and ask for help. WARN means an
auth step below still needs doing. To re-run this check any time without
rebuilding:

```sh
bash /usr/local/share/alab-desktop/bootstrap.sh
```

## 3. Authenticate — copy/paste these in the container's terminal

### AWS

```sh
aws sso login --profile <your-sso-profile-name>
```

Opens a browser to complete SSO. Since `~/.aws` is mounted read-write, this
refreshes the same cached session your host uses — you won't need to repeat
this on the host separately. Verify:

```sh
aws sts get-caller-identity
```

### GitHub

```sh
gh auth login
```

Follow the prompts (browser-based is easiest). Alternatively, use VS Code's
built-in GitHub auth (bottom-left account icon) — either way works. Verify:

```sh
gh auth status
```

### dbt Platform

No login command — instead, get `dbt_cloud.yml` onto your host once:

1. In dbt Platform: **Account settings → Your profile → VS Code Extension →
   Download credentials**.
2. Move it into place on your **host** machine (not inside the container):
   ```sh
   mkdir -p ~/.dbt && mv ~/Downloads/dbt_cloud.yml ~/.dbt/dbt_cloud.yml
   ```
3. Rebuild/reopen the container — it's now visible at
   `/home/vscode/.dbt/dbt_cloud.yml` inside.

Verify:

```sh
dbt debug
```

If this is your first time on this project, hydrate your local connection
details:

```sh
dbt init
```

### Claude Code

```sh
claude
```

Follow the sign-in prompt. Your session persists across rebuilds (mounted
volume) — you only need to do this once per machine, not per repo.

## 4. You're set

Run `bash /usr/local/share/alab-desktop/bootstrap.sh` one more time — every
line should read PASS. If something still fails after following the steps
above, check
[data-engg-alab-desktop](https://github.com/jonzakaras/data-engg-alab-desktop)'s
README/issues, or ask in #data-eng-tools.

## Gotcha: pulling in a newer desktop image

When `data-engg-alab-desktop` publishes an update, "Reopen/Rebuild Container"
doesn't always re-pull `:latest` — it can silently reuse whatever's cached
locally. If something that was recently fixed still seems broken, force it:

```sh
docker pull ghcr.io/jonzakaras/alab-desktop:latest
```

Then **Dev Containers: Rebuild Container Without Cache** from the Command
Palette.
