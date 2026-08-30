#!/usr/bin/env bash
# postCreateCommand: verifies the toolchain installed correctly and reports
# per-developer auth status. Warns (doesn't block) on missing auth, since not
# every task needs every credential — but never fails silently.
set -uo pipefail

declare -a RESULTS=()
record() { RESULTS+=("$1|$2|$3"); }  # status|check|detail

echo "== alab-desktop bootstrap =="
echo

# --- 1. Tool sanity: hard requirement, the image itself is broken if these fail
TOOLS_OK=1
check_tool() {
    local name="$1" cmd="$2"
    if ! eval "$cmd" >/dev/null 2>&1; then
        record "FAIL" "$name" "not found or not runnable — the image build is broken, contact #data-eng-tools"
        TOOLS_OK=0
    else
        record "PASS" "$name" "installed"
    fi
}
check_tool "python3"    "python3 --version"
check_tool "dbt"        "dbt --version"
check_tool "sqlfluff"   "sqlfluff --version"
check_tool "aws"        "aws --version"
check_tool "claude"     "claude --version"
check_tool "node"       "node --version"
check_tool "gh"         "gh --version"
check_tool "prettier"   "prettier --version"

# --- 2. AWS auth (warn only) --------------------------------------------------
if aws sts get-caller-identity >/dev/null 2>&1; then
    record "PASS" "AWS auth" "authenticated"
else
    record "WARN" "AWS auth" "not authenticated. Run 'aws sso login --profile <name>' or mount ~/.aws. See README."
fi

# --- 3. GitHub auth (warn only) ----------------------------------------------
if gh auth status >/dev/null 2>&1; then
    record "PASS" "GitHub auth" "authenticated"
else
    record "WARN" "GitHub auth" "not authenticated. Run 'gh auth login', or use VS Code's built-in GitHub auth."
fi

# --- 4. dbt Cloud env vars (warn only) ----------------------------------------
if [[ -n "${DBT_CLOUD_API_TOKEN:-}" && -n "${DBT_CLOUD_ACCOUNT_ID:-}" ]]; then
    record "PASS" "dbt Cloud env" "DBT_CLOUD_API_TOKEN / DBT_CLOUD_ACCOUNT_ID set"
else
    record "WARN" "dbt Cloud env" "DBT_CLOUD_API_TOKEN / DBT_CLOUD_ACCOUNT_ID not set. Add them to your devcontainer.json containerEnv. See README."
fi

# --- 5. Claude Code reminder (always shown) -----------------------------------
record "INFO" "Claude Code" "run 'claude' to sign in — your session persists across rebuilds via the mounted volume."

# --- Summary -------------------------------------------------------------------
echo "--------------------------------------------------------------------------------"
printf "%-6s %-14s %s\n" "STATUS" "CHECK" "DETAIL"
echo "--------------------------------------------------------------------------------"
for row in "${RESULTS[@]}"; do
    IFS='|' read -r status check detail <<< "$row"
    printf "%-6s %-14s %s\n" "$status" "$check" "$detail"
done
echo "--------------------------------------------------------------------------------"
echo

if [[ "$TOOLS_OK" -eq 0 ]]; then
    echo "One or more required tools failed to install. This container is not usable as-is."
    exit 1
fi

echo "Bootstrap complete. Review any WARN lines above before starting work."
