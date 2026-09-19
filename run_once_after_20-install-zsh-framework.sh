#!/usr/bin/env bash
# .zshrc expects oh-my-zsh plus these custom plugins/theme under ~/.oh-my-zsh;
# nothing else installs them, so a fresh machine's first shell would error.
# Plain git clones (not the oh-my-zsh installer, which rewrites ~/.zshrc).
# Idempotent: skips anything already cloned.
set -euo pipefail

ZSH="$HOME/.oh-my-zsh"
CUSTOM="$ZSH/custom"

clone() {
  local url="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    echo "already present: $dest"
  else
    git clone --depth=1 "$url" "$dest"
  fi
}

clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
clone https://github.com/romkatv/powerlevel10k.git "$CUSTOM/themes/powerlevel10k"
clone https://github.com/lukechilds/zsh-nvm "$CUSTOM/plugins/zsh-nvm"
clone https://github.com/marlonrichert/zsh-autocomplete.git "$CUSTOM/plugins/zsh-autocomplete"
clone https://github.com/zsh-users/zsh-autosuggestions.git "$CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
