# Use vi for Git messages without changing other programs' editor.
export GIT_EDITOR=vi

# macOS-style names for the Wayland clipboard.
alias pbcopy='wl-copy'
alias pbpaste='wl-paste --no-newline'

# Append this shell's commands, then import commands from other Bash sessions.
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend
_dotfiles_sync_history() {
  local status=$?
  # Full reload avoids history -n's stale file offsets when shells interleave.
  # Never clear unsaved history if writing fails or history is disabled.
  if [[ -n ${HISTFILE:-} ]] && builtin history -a && [[ -r $HISTFILE ]]; then
    builtin history -c
    builtin history -r
  fi
  return "$status"
}

# Preserve scalar or array prompt hooks (including their incoming exit status).
# Re-sourcing this file must not install the history hook twice.
_dotfiles_install_history_hook() {
  local hook
  for hook in "${PROMPT_COMMAND[@]}"; do
    [[ $hook == _dotfiles_sync_history ]] && return 0
  done
  PROMPT_COMMAND=(_dotfiles_sync_history "${PROMPT_COMMAND[@]}")
}
_dotfiles_install_history_hook
unset -f _dotfiles_install_history_hook
