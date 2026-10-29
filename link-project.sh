#!/usr/bin/env bash
# Points a project checkout at one of this repo's dev shells without committing
# anything to it: writes an untracked .envrc and hides it, and .direnv/, via
# the checkout's .git/info/exclude.
#
#   link-project.sh <devshell> [project-dir]
set -euo pipefail

die() { echo "link-project: $*" >&2; exit 1; }

shell=${1:?usage: link-project.sh <devshell> [project-dir]}
project=$(cd "${2:-.}" && pwd)
flake=$(cd "$(dirname "$0")" && pwd)

[[ -f $flake/devshells/$shell.nix ]] || die "no devshells/$shell.nix in $flake"
[[ -e $project/.envrc ]] && die "$project/.envrc exists; remove it to relink"

cat >"$project/.envrc" <<EOF
# Written by $flake/link-project.sh; untracked via .git/info/exclude.
watch_file $flake/devshells/$shell.nix
use flake $flake#$shell
EOF

exclude=$(git -C "$project" rev-parse --path-format=absolute --git-path info/exclude)
mkdir -p "$(dirname "$exclude")"
for pattern in .envrc .direnv/; do
  grep -qxF "$pattern" "$exclude" 2>/dev/null || echo "$pattern" >>"$exclude"
done

direnv allow "$project"

if [[ -e $project/shell.nix ]]; then
  echo "link-project: $project/shell.nix also defines a Nix shell; consider removing it so the two don't drift." >&2
fi
