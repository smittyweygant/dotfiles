#!/usr/bin/env bash
# .vimrc centralizes backups/swaps/undo history into these dirs; vim won't
# create them itself, so make sure they exist before vim tries to write to them.
mkdir -p "$HOME/.vim/backups" "$HOME/.vim/swaps" "$HOME/.vim/undo"
