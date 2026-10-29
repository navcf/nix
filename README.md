# nix

Nix based development environment for macOS: a home-manager configuration
(zsh, direnv, nix-direnv) and per-toolchain dev shells that load on `cd`
without adding Nix files to the projects themselves.

## Bootstrap

Needs macOS and [Homebrew](https://brew.sh).

```sh
curl -fsSL https://raw.githubusercontent.com/navcf/nix/main/bootstrap.sh | bash
```

This installs Nix (multi-user) if missing, clones this repo to
`~/.config/home-manager`, installs the `Brewfile`, enables the commit hooks,
and runs `home-manager switch`. Dotfiles it replaces are kept as
`<file>.hm-backup-<timestamp>`. Every step checks before acting, so re-running
it is safe; it never pulls or overwrites an existing clone.

Nix's shell setup is sourced from `~/.zshenv` and `~/.zshrc`, so it survives
macOS upgrades rewriting `/etc/zshrc`. Machine-specific or private settings go
in `~/.zshenv.local`, which `~/.zshenv` sources and this repo never contains.

## Link a project

```sh
~/.config/home-manager/link-project.sh node22 ~/path/to/project
```

This writes an untracked `.envrc` that loads `devShells.<system>.node22`, adds
`.envrc` and `.direnv/` to the checkout's `.git/info/exclude`, and runs
`direnv allow`. nix-direnv caches the shell; it re-evaluates only when
`flake.nix`, `flake.lock` or `devshells/<name>.nix` change. Each git worktree
needs its own link.

If the project has its own `shell.nix`, remove it so there is one Nix setup.

## Everyday use

| Task | Command |
|------|---------|
| Apply home config changes | `home-manager switch` |
| Update home packages | `nix flake update nixpkgs home-manager && home-manager switch` |
| Update a dev shell | `nix flake update nixpkgs-node22` |
| Add a dev shell | add `devshells/<name>.nix` (and a `nixpkgs-<name>` input to pin it), wire it in `flake.nix` |

New files must be `git add`ed before Nix sees them.

After updating `nixpkgs-node22`, check that `node --version` in each linked
project matches `devEngines.runtime` in its `package.json`; pnpm refuses to
run on a mismatch.

## Commit hooks

This repo is public. `.githooks/` (enabled by `bootstrap.sh` through
`core.hooksPath`) blocks a commit when:

- gitleaks finds a secret in the staged changes;
- trivy finds a secret or misconfiguration in the working tree;
- shellcheck fails on a staged shell script;
- the staged diff, file names, author, committer or message contain a term
  from `~/.config/public-repo-denylist`, one per line. Keep employer, internal
  repository and host names there. The list lives outside the repo so the
  terms stay private.

Commit as your GitHub noreply address
(`git config user.email <id>+<login>@users.noreply.github.com`) so a work email
never lands in history.
