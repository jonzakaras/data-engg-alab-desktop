#!/usr/bin/env bash
# OPTIONAL hardening — NOT wired into devcontainer.json by default.
#
# Restricts the container's outbound network traffic to an allowlist of domains
# needed by Claude Code and this toolchain (Anthropic API/auth, GHCR, GitHub,
# PyPI, npm, AWS, dbt Cloud, ASU internal services). Requires NET_ADMIN and
# NET_RAW capabilities, which is why it isn't a default for a general-purpose
# team image — most repos don't need it and granting those capabilities by
# default is unusual.
#
# To use: add to your devcontainer.json:
#   "runArgs": ["--cap-add=NET_ADMIN", "--cap-add=NET_RAW"],
#   "postStartCommand": "sudo bash .devcontainer/init-firewall.sh"
#
# Adjust ALLOWED_DOMAINS below to match your team's actual egress needs before
# enabling this in any repo.
set -euo pipefail

ALLOWED_DOMAINS=(
    api.anthropic.com
    console.anthropic.com
    ghcr.io
    github.com
    api.github.com
    raw.githubusercontent.com
    pypi.org
    files.pythonhosted.org
    registry.npmjs.org
    cloud.getdbt.com
    "*.amazonaws.com"
    "*.asu.edu"
)

echo "init-firewall.sh is a template — fill in your organization's actual egress"
echo "policy (iptables/ipset rules restricting to the domains above) before relying"
echo "on this for real network isolation. See:"
echo "https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh"
echo "for a maintained reference implementation."
exit 1
