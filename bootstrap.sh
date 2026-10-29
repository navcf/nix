#!/usr/bin/env bash
# Sets up a macOS machine from this repo: Nix, Homebrew packages, then
# home-manager, which installs direnv, nix-direnv and the zsh config.
# Idempotent: every step checks or converges, so re-running is safe.
#
#   curl -fsSL https://raw.githubusercontent.com/navcf/nix/main/bootstrap.sh | bash
set -euo pipefail

repo_url=https://github.com/navcf/nix.git
dest="$HOME/.config/home-manager"
nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
denylist="${XDG_CONFIG_HOME:-$HOME/.config}/public-repo-denylist"

log() { echo "bootstrap: $*"; }
die() { echo "bootstrap: $*" >&2; exit 1; }

install_nix() {
  if [[ -e $nix_profile ]]; then
    log "Nix already installed"
  else
    local installer
    installer=$(mktemp)
    curl -fsSL https://nixos.org/nix/install -o "$installer"
    sh "$installer" --daemon --yes </dev/null
    rm -f "$installer"
  fi
  # The profile script reads unset variables.
  set +u
  # shellcheck source=/dev/null
  . "$nix_profile"
  set -u
}

clone_repo() {
  if [[ -d $dest/.git ]]; then
    local origin
    origin=$(git -C "$dest" remote get-url origin 2>/dev/null || true)
    [[ ${origin%.git} == "${repo_url%.git}" ]] || die "$dest is a clone of '$origin', not $repo_url"
    log "$dest already cloned; leaving it as is (git pull to update)"
  elif [[ -e $dest ]]; then
    die "$dest exists and is not a clone of $repo_url; move it aside first"
  else
    git clone "$repo_url" "$dest"
  fi
}

install_hooks() {
  git -C "$dest" config core.hooksPath .githooks
  if [[ ! -e $denylist ]]; then
    printf '%s\n' \
      '# One term per line, matched case-insensitively. Commits to public repos' \
      '# whose diff, file names, message or author contain one are blocked.' \
      >"$denylist"
    log "created $denylist; add employer, internal repo and host names to it"
  fi
}

switch_home() {
  # --inputs-from runs the home-manager version this flake locks. Flakes are off
  # until home-manager writes ~/.config/nix/nix.conf. A timestamped backup
  # suffix never collides with an earlier run's backups.
  NIX_CONFIG='experimental-features = nix-command flakes' \
    nix run --inputs-from "$dest" home-manager -- \
    switch --flake "$dest#$(id -un)" -b "hm-backup-$(date +%Y%m%d%H%M%S)" </dev/null
}

main() {
  [[ $(uname -s) == Darwin ]] || die "macOS only"
  command -v brew >/dev/null || die "Homebrew is required: https://brew.sh"

  install_nix
  clone_repo
  brew bundle --no-upgrade --file "$dest/Brewfile" </dev/null
  install_hooks
  switch_home

  log "done. Open a new terminal, then link a project:"
  log "  $dest/link-project.sh node22 ~/path/to/project"
}

# Called last so a piped (curl | bash) run is fully read before anything executes.
main "$@"
