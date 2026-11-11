#!/usr/bin/env bash
# Points this clone at the tracked hooks in init/git-hooks. Git hooks are not
# versioned, so each machine opts in once.
set -euo pipefail

# chezmoi holds its state lock while it runs scripts, so `chezmoi source-path`
# would wait on that lock and fail; it exports the directory instead.
git -C "$CHEZMOI_SOURCE_DIR" config core.hooksPath init/git-hooks
