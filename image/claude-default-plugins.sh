#!/bin/sh
# claude-default-plugins — turn the image's bundled plugins on in Claude Code's user settings.
# Run by the image's postCreateCommand. Only adds plugins the user settings don't mention yet,
# so a user's own `false` survives rebuilds; a repo opts out in its .claude/settings.json
# (project settings take precedence over user settings).
set -eu

dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
f=$dir/settings.json
defaults='{"mentor@mentor": true, "personas@mentor": true}'

mkdir -p "$dir"
[ -s "$f" ] || echo '{}' > "$f"
tmp=$(mktemp "$dir/.settings.json.XXXXXX")
trap 'rm -f "$tmp"' EXIT
jq --argjson d "$defaults" '.enabledPlugins = ($d + (.enabledPlugins // {}))' "$f" > "$tmp" \
  || { echo "claude-default-plugins: $f is not valid JSON; left unchanged" >&2; exit 1; }
mv "$tmp" "$f"
