# Sourced from ~/.bashrc. Shows a fixed "alab-desktop" tag plus the current
# git branch (when in a repo), so it's obvious you're inside the standardized
# container regardless of which project you're working in — e.g.:
#   alab-desktop (main) $
__alab_desktop_git_branch() {
    git branch --show-current 2>/dev/null
}

PS1='alab-desktop$(b=$(__alab_desktop_git_branch); [ -n "$b" ] && printf " (%s)" "$b") \$ '
