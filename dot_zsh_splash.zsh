#!/usr/bin/env zsh
# Personalized splash screen. Shown once per new terminal window (dedup keyed
# off iTerm2's per-window session id when available — new panes/tabs in the
# same window won't re-trigger it, but plain SSH sessions, tmux windows, or
# terminals without that id will show it every time, which is fine).

_zsh_splash() {
  emulate -L zsh
  local reset=$'\e[0m' bold=$'\e[1m' dim=$'\e[2m'
  local cyan=$'\e[36m' magenta=$'\e[35m' green=$'\e[32m'

  print
  printf '%s' "${bold}${cyan}"
  printf '%s\n' '   _____ __  _____________________  __'
  printf '%s\n' '  / ___//  |/  /  _/_  __/_  __/\ \/ /'
  printf '%s\n' '  \__ \/ /|_/ // /  / /   / /    \  / '
  printf '%s\n' ' ___/ / /  / // /  / /   / /     / /  '
  printf '%s\n' '/____/_/  /_/___/ /_/   /_/     /_/   '
  printf '%s' "${reset}${dim}${magenta}"
  printf '%s\n' '            Human in the Loop'
  printf '%s' "${reset}"
  print

  local modules="${(j:, :)plugins}"
  printf '%s%s%s %s✓%s %s\n' "$bold" "Loading useful modules..." "$reset" "$green" "$reset" "$modules"
  sleep 0.08

  local n_aliases n_functions
  n_aliases=$(grep -c '^alias ' ~/.aliases 2>/dev/null)
  n_functions=$(grep -c '^function ' ~/.functions 2>/dev/null)
  printf '%s%s%s %s✓%s %s aliases, %s functions, several of dubious necessity\n' \
    "$bold" "Loading not-so-useful but interesting things..." "$reset" "$green" "$reset" \
    "${n_aliases:-0}" "${n_functions:-0}"
  sleep 0.08

  local ctx branch
  ctx="$(hostname -s 2>/dev/null)"
  [[ -n "$SSH_CONNECTION" ]] && ctx="${ctx} · via ssh"
  (( ${+commands[direnv]} )) && ctx="${ctx} · direnv ready"
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [[ -n "$branch" ]] && ctx="${ctx} · on ${branch}"
  printf '%s%s%s %s✓%s %s\n' "$bold" "Loading context and environment..." "$reset" "$green" "$reset" "$ctx"

  print
}

if [[ -o interactive && -t 1 ]]; then
  _splash_key=""
  if [[ -n "$ITERM_SESSION_ID" ]]; then
    _splash_key="${ITERM_SESSION_ID%%t*}"
  fi

  # iTerm2 reuses window-index numbers across separate window lifetimes (close
  # a window, open a new one, it can get the same index) — so a plain
  # "marker file exists" check can end up suppressing the splash permanently
  # after the first window of a boot session. Treat markers older than 4
  # hours as stale instead, so a genuinely new window still gets the splash.
  _splash_show=1
  if [[ -n "$_splash_key" ]]; then
    zmodload zsh/stat 2>/dev/null
    zmodload zsh/datetime 2>/dev/null
    _splash_marker="${TMPDIR:-/tmp}/.zsh-splash-${_splash_key}-${UID}"
    if [[ -f "$_splash_marker" ]]; then
      _splash_mtime=0
      zstat -A _splash_stat +mtime -- "$_splash_marker" 2>/dev/null && _splash_mtime=${_splash_stat[1]}
      (( EPOCHSECONDS - _splash_mtime < 14400 )) && _splash_show=0
    fi
  fi

  if (( _splash_show )); then
    [[ -n "$_splash_marker" ]] && touch "$_splash_marker" 2>/dev/null
    _zsh_splash
  fi

  unset _splash_key _splash_marker _splash_show _splash_mtime _splash_stat
fi
