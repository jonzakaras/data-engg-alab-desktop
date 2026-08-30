# Pinned to noble (Ubuntu 24.04 LTS) rather than the floating `ubuntu` tag:
# its system python3 is 3.12, which is what this image standardizes on, and
# pinning keeps the base OS from silently jumping to a new LTS on rebuild.
FROM mcr.microsoft.com/devcontainers/base:noble

ARG CLAUDE_CODE_VERSION=2.0.1
ARG NODE_VERSION=20
ARG DBT_CLI_VERSION=0.40.23
# dbt Fusion has no semver release cadence yet (pre-1.0, frequent internal
# builds) — pinned to a named release channel, not an exact build. See the
# Fusion install step below for what this actually does.
ARG DBT_FUSION_CHANNEL=stable
# Set automatically by buildx for each platform in a multi-arch build
# (linux/amd64 -> amd64, linux/arm64 -> arm64) — used below to pick the right
# AWS CLI / dbt CLI installer.
ARG TARGETARCH

# --- OS packages (rarely change) --------------------------------------------
# python3.12 is noble's native system Python — no PPA needed.
RUN apt-get update && apt-get install -y --no-install-recommends \
        unzip \
        curl \
        ca-certificates \
        gnupg \
        jq \
        pipx \
        python3.12 \
        python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# --- GitHub CLI (apt repo) ---------------------------------------------------
# Needed by bootstrap.sh's `gh auth status` check.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# --- AWS CLI v2 (official installer — apt's package lags behind) -----------
# The installer URL is arch-specific (x86_64 / aarch64), unlike TARGETARCH's
# amd64 / arm64 naming, hence the mapping below.
RUN case "${TARGETARCH}" in \
        amd64) AWSCLI_ARCH=x86_64 ;; \
        arm64) AWSCLI_ARCH=aarch64 ;; \
        *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# --- dbt CLI (official dbt Labs binary, for the dbt platform) ---------------
# This is dbt Labs' own CLI (github.com/dbt-labs/dbt-cli) — connects to dbt
# Platform via a ~/.dbt/dbt_cloud.yml credentials file and runs models
# locally (dbt build/run/debug/parse). Distinct from the third-party PyPI
# package literally named "dbt-cloud-cli", which is API-only account/job
# management and was removed in favor of this. TARGETARCH's amd64/arm64
# naming matches this release's asset names directly, unlike AWS CLI above.
RUN curl -sSL "https://github.com/dbt-labs/dbt-cli/releases/download/v${DBT_CLI_VERSION}/dbt_${DBT_CLI_VERSION}_linux_${TARGETARCH}.tar.gz" -o /tmp/dbt-cli.tar.gz \
    && tar -xzf /tmp/dbt-cli.tar.gz -C /usr/local/bin dbt \
    && chmod +x /usr/local/bin/dbt \
    && rm -f /tmp/dbt-cli.tar.gz

# --- Node.js (required by Claude Code, and later Codex) ---------------------
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Prettier ------------------------------------------------------------
# Intentionally unpinned — always installs whatever is latest at build time.
RUN npm install -g prettier

# --- Claude Code -------------------------------------------------------------
# Pinned explicitly (bump CLAUDE_CODE_VERSION via PR) rather than using the
# always-latest devcontainer feature, so image builds stay reproducible.
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# --- Codex slot (future) -----------------------------------------------------
# When Codex CLI's install mechanism is confirmed, add here following the same
# shape as Claude Code above:
#   ARG CODEX_CLI_VERSION=x.y.z
#   RUN npm install -g <codex-package>@${CODEX_CLI_VERSION}
# See docs/adding-a-new-ai-cli.md for the full checklist.

# --- Org policy + bootstrap script -------------------------------------------
COPY managed-settings.json /etc/claude-code/managed-settings.json
COPY bootstrap.sh /usr/local/share/alab-desktop/bootstrap.sh
RUN chmod +x /usr/local/share/alab-desktop/bootstrap.sh

# --- Shell prompt -------------------------------------------------------------
# Tags the terminal as "alab-desktop (<branch>) $" so it's obvious you're in
# the standardized container, regardless of which repo you're working in.
COPY bash-prompt.sh /usr/local/share/alab-desktop/bash-prompt.sh
RUN echo '[ -f /usr/local/share/alab-desktop/bash-prompt.sh ] && source /usr/local/share/alab-desktop/bash-prompt.sh' \
        >> /home/vscode/.bashrc

# --- Python CLI tools via pipx ------------------------------------------------
# pipx isolates the tool's dependencies and needs no venv activation to run
# `sqlfluff` as a command. Installed as `vscode` (not root) since pipx
# installs into the invoking user's home directory — PATH is set explicitly
# rather than relying on `pipx ensurepath` editing shell rc files, which
# non-interactive shells (postCreateCommand, CI) won't source.
USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Pre-create the Claude Code config dir owned by `vscode` before any volume is
# mounted here. Docker seeds a freshly-created named volume from whatever
# already exists at the mount point in the image — if this directory didn't
# exist here, Docker would create it itself owned by root, and the non-root
# `vscode` user would get EACCES writing ~/.claude/.claude.json.
RUN mkdir -p /home/vscode/.claude

# Same reasoning for ~/.dbt: dbt_cloud.yml gets mounted/written there, and it
# needs to exist here owned by vscode before that happens.
RUN mkdir -p /home/vscode/.dbt

RUN pipx install sqlfluff

# --- dbt Fusion (separate engine; powers the dbtLabsInc.dbt VS Code extension) ---
# Fusion is NOT the dbt CLI installed above — that one self-identifies as
# "dbt Cloud CLI" and is what `dbt` on PATH resolves to for terminal runs.
# The dbtLabsInc.dbt extension's LSP (autocomplete, live SQL preview, error
# highlighting) only talks to Fusion; dbt Cloud CLI and dbt-core are engines
# it doesn't speak to at all. They're designed to coexist rather than
# replace one another:
#   - Fusion installs to its own directory, kept off the front of PATH, so
#     plain `dbt` in a terminal keeps resolving to dbt Cloud CLI above.
#   - The installer wires a `dbtf` alias into ~/.bashrc for invoking Fusion
#     explicitly from a terminal.
#   - The VS Code extension doesn't see shell aliases (it spawns the binary
#     directly), so `dbt.dbtPath` is set explicitly in devcontainer.json to
#     this same install path — without it, the extension falls back to
#     "standard locations" (PATH), finds dbt Cloud CLI first, and errors
#     with "The dbt Fusion engine is required for this command."
# Current releases ship a single ~250MB unified binary (CLI + language
# server in one) — there's no separate dbt-lsp file to install alongside it.
# jq (installed above) is a hard dependency of this installer script;
# pre-installing it via apt avoids the script fetching its own copy.
#
# Note: Redshift support in Fusion itself is "Preview" as of writing. This
# only backs the VS Code extension's local LSP features, not a guarantee
# that `dbtf` fully works against this warehouse — day-to-day runs should
# still go through `dbt` (dbt Cloud CLI) above.
# SHELL is exported explicitly: it's unset in a non-interactive RUN step,
# and the installer's `set -u` mode errors on referencing it unset.
RUN export SHELL=/bin/bash \
    && curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh \
        | sh -s -- --version ${DBT_FUSION_CHANNEL} --to /home/vscode/.local/share/dbt-fusion/bin

WORKDIR /workspace
