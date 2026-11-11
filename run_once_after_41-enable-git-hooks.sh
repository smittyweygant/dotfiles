#!/usr/bin/env bash
# Points this clone at the tracked hooks in init/git-hooks. Git hooks are not
# versioned, so each machine opts in once.
set -euo pipefail

git -C "$(chezmoi source-path)" config core.hooksPath init/git-hooks
