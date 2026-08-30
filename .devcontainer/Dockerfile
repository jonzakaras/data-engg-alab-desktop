# Pinned to noble (Ubuntu 24.04 LTS) rather than the floating `ubuntu` tag:
# its system python3 is 3.12, which is what this image standardizes on, and
# pinning keeps the base OS from silently jumping to a new LTS on rebuild.
FROM mcr.microsoft.com/devcontainers/base:noble

ARG CLAUDE_CODE_VERSION=2.0.1
ARG NODE_VERSION=20
# Set automatically by buildx for each platform in a multi-arch build
# (linux/amd64 -> amd64, linux/arm64 -> arm64) — used below to pick the right
# AWS CLI installer.
ARG TARGETARCH

# --- OS packages (rarely change) --------------------------------------------
# python3.12 is noble's native system Python — no PPA needed.
RUN apt-get update && apt-get install -y --no-install-recommends \
        unzip \
        curl \
        ca-certificates \
        gnupg \
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

# --- Python CLI tools via pipx ------------------------------------------------
# pipx isolates each tool's dependencies (no conflicts between dbt-cloud-cli and
# sqlfluff) and needs no venv activation to run `dbt`/`sqlfluff` as commands.
# Installed as `vscode` (not root) since pipx installs into the invoking user's
# home directory — PATH is set explicitly rather than relying on `pipx ensurepath`
# editing shell rc files, which non-interactive shells (postCreateCommand, CI) won't source.
USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Pre-create the Claude Code config dir owned by `vscode` before any volume is
# mounted here. Docker seeds a freshly-created named volume from whatever
# already exists at the mount point in the image — if this directory didn't
# exist here, Docker would create it itself owned by root, and the non-root
# `vscode` user would get EACCES writing ~/.claude/.claude.json.
RUN mkdir -p /home/vscode/.claude

RUN pipx install dbt-cloud-cli \
    && pipx install sqlfluff

WORKDIR /workspace
