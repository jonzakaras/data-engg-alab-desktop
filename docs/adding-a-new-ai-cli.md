# Adding a new AI CLI (e.g. Codex)

Claude Code ships today. This image is structured so a second AI CLI can be
added later without reworking anything else — the same install pattern,
the same config-persistence pattern, the same devcontainer.json shape.

Once the new CLI's install mechanism is confirmed, touch exactly these files:

1. **`.devcontainer/Dockerfile`** — add one `ARG <NAME>_CLI_VERSION=x.y.z` and
   one `RUN npm install -g <package>@${<NAME>_CLI_VERSION}` (or the equivalent
   install command) in the same layer position as the Claude Code install
   (after Node.js, before the org-policy/bootstrap COPY steps).
2. **`.devcontainer/managed-settings.json`** — if the new CLI supports an
   org-policy/managed-settings file, `COPY` it into the image the same way
   Claude Code's is, at its own path.
3. **`.devcontainer/devcontainer.json`** and **`templates/devcontainer.json`**
   — add one more `mounts` entry for its config volume
   (`source=<name>-config-${devcontainerId},target=/home/vscode/.<name>,type=volume`)
   and one more `containerEnv` var for its config-dir/auto-update equivalent.
4. **`.devcontainer/bootstrap.sh`** — add one more `check_tool` line and one
   more login reminder, matching the Claude Code entries.
5. **This file** — flip from a forward-looking recipe to a changelog entry
   noting the new CLI now follows this pattern.

No changes are needed to the CI workflows, the base image, or the AWS/dbt/SQLFluff
layers — that's the point of the design: adding a second AI CLI is additive,
not a rework.
