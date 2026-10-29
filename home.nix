{ config, lib, ... }:

let
  nixDaemon = ''
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
  direnv = "${config.programs.direnv.package}/bin/direnv";
in
{
  home.username = "nav";
  home.homeDirectory = "/Users/nav";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';

  # Project dev shells load on cd from each repo's .envrc; nix-direnv caches
  # them so only flake.nix/flake.lock edits re-evaluate.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  programs.zsh = {
    enable = true;
    # oh-my-zsh runs compinit itself.
    enableCompletion = false;

    # macOS upgrades rewrite /etc/zshrc and drop the Nix installer's block;
    # ~/.zshenv survives them and covers non-interactive shells.
    # Machine-specific or private settings go in ~/.zshenv.local, kept out of
    # this public repo.
    envExtra = ''
      ${nixDaemon}
      [[ -r $HOME/.zshenv.local ]] && source $HOME/.zshenv.local
    '';

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "fzf"
      ];
    };

    history = {
      path = "$HOME/.zsh_history";
      size = 1000000;
      save = 1000000;
      share = true;
      extended = true;
      append = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreAllDups = true;
      findNoDups = true;
      ignoreSpace = true;
      saveNoDups = true;
    };

    shellAliases = {
      history = "history 0";
      dc = "docker compose";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # path_helper (/etc/zprofile) and brew shellenv moved the Nix profile
        # behind system and Homebrew paths; re-source where /etc/zshrc used to.
        unset __ETC_PROFILE_NIX_SOURCED
        ${nixDaemon}
        # A shell started inside a direnv-loaded directory inherits its env, but
        # startup files above reordered PATH. Unload so the first prompt reloads.
        if [[ -n ''${DIRENV_DIFF-} ]]; then
          eval "$(cd / && ${direnv} export zsh)"
        fi
      '')
      (lib.mkOrder 550 ''
        export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
      '')
      ''
        setopt INC_APPEND_HISTORY
        setopt HIST_REDUCE_BLANKS

        export PATH=$PATH:$HOME/.pulumi/bin

        # direnv prepends its hook to precmd_functions, so this sees the updated
        # IN_NIX_SHELL when entering or leaving a dev shell.
        _nix_shell_prompt_icon() {
          PROMPT=''${PROMPT#❄ }
          [[ -n $IN_NIX_SHELL ]] && PROMPT="❄ $PROMPT"
        }
        precmd_functions+=(_nix_shell_prompt_icon)
      ''
    ];
  };
}
