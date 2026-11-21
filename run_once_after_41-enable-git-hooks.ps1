# Windows twin of run_once_after_41-enable-git-hooks.sh: points this clone at
# the tracked hooks in init/git-hooks. Git for Windows runs hook scripts with
# its own bash, so the pre-commit guard works unchanged.
$ErrorActionPreference = 'Stop'

git -C $env:CHEZMOI_SOURCE_DIR config core.hooksPath init/git-hooks
exit $LASTEXITCODE
