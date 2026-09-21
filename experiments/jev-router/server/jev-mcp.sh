#!/bin/zsh
set -euo pipefail

JEV_KEY="${TYPESAFE_API_KEY:-}"
if [[ -z "$JEV_KEY" ]]; then
  JEV_KEY="$(security find-generic-password -s 'Typesafe codex' -a api-key -w 2>/dev/null || true)"
fi
if [[ -z "$JEV_KEY" ]]; then
  JEV_KEY="$(security find-generic-password -s exco-agent-secrets -a TYPESAFE_API_KEY -w 2>/dev/null || true)"
fi
[[ -n "$JEV_KEY" ]] || { print -u2 'TypeSafe API key not found in Keychain'; exit 1; }

NPX="$(command -v npx || true)"
if [[ -z "$NPX" ]]; then
  NPX="$(find "$HOME/.nvm/versions/node" -path '*/bin/npx' -type f 2>/dev/null | sort -V | tail -1)"
fi
[[ -x "$NPX" ]] || { print -u2 'npx not found'; exit 1; }

exec env TYPESAFE_API_KEY="$JEV_KEY" "$NPX" -y @jkudish/jev-mcp
