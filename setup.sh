#!/usr/bin/env bash
# Apply the user-owned desktop layer. No sudo, package upgrades, or session restart.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin="$HOME/.config/omarchy/plugins/io.github.nchudleigh.omac"
omac_commit=fe434579e7fa9dc0fa3d0f87905cf4fd057fd4f1
mode=${1:-}
case "$mode" in ""|--check|--remove) ;; *) echo "Usage: $0 [--check|--remove]" >&2; exit 2 ;; esac
for cmd in python3 hyprctl omarchy git systemctl hyprsunset; do
  command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
[[ -f /usr/share/omarchy/default/hypr/toggles.lua ]] || {
  echo "Requires a Lua-based Omarchy installation. Review compatibility before applying." >&2
  exit 1
}
if [[ "$mode" == --remove ]]; then
  # Clean up our idle request while its executable is still linked.
  systemctl --user stop dotfiles-hot-corner.service || true
  for id in personal.switcher personal.workspace-label; do
    omarchy plugin disable "$id" || true
  done
  python3 "$repo/link.py" --remove
elif [[ "$mode" == --check ]]; then
  python3 "$repo/link.py" --check
  [[ -f "$plugin/hypr/omac.lua" ]] || { echo "omac is missing" >&2; exit 1; }
  omarchy plugin list | grep -E '^io\.github\.nchudleigh\.omac[[:space:]]+enabled' >/dev/null || {
    echo "omac is not enabled" >&2; exit 1;
  }
  for id in personal.switcher personal.workspace-label; do
    omarchy plugin list | grep -E "^${id//./\\.}[[:space:]]+enabled" >/dev/null || {
      echo "$id is not enabled" >&2; exit 1;
    }
  done
else
  if [[ ! -d "$plugin" ]]; then
    mkdir -p "$(dirname "$plugin")"
    checkout=$(mktemp -d "$(dirname "$plugin")/.omac-setup.XXXXXX")
    trap 'rm -rf -- "$checkout"' EXIT
    git clone --no-checkout https://github.com/nchudleigh/omac "$checkout"
    git -C "$checkout" checkout --detach "$omac_commit"
    mv -- "$checkout" "$plugin"
    trap - EXIT
  fi
  # Never reset an existing plugin checkout or discard its local changes.
  if [[ -d "$plugin/.git" ]] && [[ $(git -C "$plugin" rev-parse HEAD) != "$omac_commit" ]]; then
    echo "Note: existing omac differs from the tested pin; leaving it untouched." >&2
  fi
  python3 "$repo/link.py"
  bash "$plugin/install.sh"
  omarchy-shell shell rescanPlugins
  omarchy plugin enable io.github.nchudleigh.omac
  # Discovery is asynchronous after new files are linked.
  for id in personal.switcher personal.workspace-label; do
    for _ in {1..50}; do
      if omarchy plugin list | grep -E "^${id//./\\.}[[:space:]]" >/dev/null; then break; fi
      sleep 0.1
    done
    omarchy plugin enable "$id"
  done
fi
if [[ "$mode" != --check ]]; then
  hyprctl reload
fi
errors=$(hyprctl configerrors)
if [[ -n ${errors//[[:space:]]/} ]]; then
  printf 'Hyprland configuration errors:\n%s\nReview the backup before continuing.\n' "$errors" >&2
  exit 1
fi
printf 'Hyprland configuration is valid.\n'
if [[ "$mode" == --remove ]]; then
  systemctl --user stop hyprsunset.service
elif [[ "$mode" != --check ]]; then
  # Restart only the tint service so it rereads our linked all-day profile.
  systemctl --user restart hyprsunset.service
  systemctl --user daemon-reload
  systemctl --user restart dotfiles-hot-corner.service
  # Solid black wallpaper, through Omarchy's supported background command.
  omarchy theme bg set "$HOME/.config/omarchy/personal/backgrounds/black.png"
fi
