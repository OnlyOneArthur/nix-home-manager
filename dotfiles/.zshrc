#### =========================
#### Arthur’s .zshrc (zinit + lazy managers)
#### =========================

# ----- Prompt via oh-my-posh (single prompt owner; no zsh themes) -----
eval "$(oh-my-posh init zsh --config $HOME/.poshthemes/themes/tokyonight_storm.omp.json)"

# ----- History tuning -----
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

# ----- Keybinds -----
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# ----- Completion (init early so others can hook in) -----
autoload -Uz compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
compinit -i

# setting up autocorrect
setopt CORRECT
# ----- Aliases (lsd) -----
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias pacupg='sudo pacman -Syu'
alias pacrem='sudo pacman -Rcns'

# general aliases
alias cat='bat'

# my custom aliases for script
export PATH="$HOME/.local/bin:$PATH"
alias obsync='obsidian-sync'
# alias pro='project.sh'
alias opencode='launchcode.sh'
alias push='autopushconfig'
alias dirmove='autorenamenix.sh'

# ----- Environment / PATHs you use -----
export LIBVIRT_DEFAULT_URI='qemu:///system'
export PATH="$HOME/.npm-global/bin:$PATH"       # npm global

# =========================
# Lazy loaders (Node tools, PNPM, fzf)
# =========================

# ----- NVM (lazy) -----
export NVM_DIR="$HOME/.nvm"

_nvm_boot() {
  # Load NVM only once, and only if present
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  else
    print -r -- "nvm: not installed (expected at $NVM_DIR)."
    return 1
  fi
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}

nvm() {
  unfunction nvm 2>/dev/null || true
  _nvm_boot || return $?
  nvm "$@"
}

node() {
  unfunction node 2>/dev/null || true
  _nvm_boot || return $?
  node "$@"
}

npm() {
  unfunction npm 2>/dev/null || true
  _nvm_boot || return $?
  npm "$@"
}

npx() {
  unfunction npx 2>/dev/null || true
  _nvm_boot || return $?
  npx "$@"
}

# ----- PNPM (lazy) -----
_pnpm_boot() {
  export PNPM_HOME="$HOME/.local/share/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
}

pnpm() {
  unfunction pnpm 2>/dev/null || true
  _pnpm_boot
  if [ -x "$PNPM_HOME/pnpm" ]; then
    command "$PNPM_HOME/pnpm" "$@"
  else
    command pnpm "$@"
  fi
}

# ----- fzf (lazy: init when first used / Ctrl-R) -----
_fzf_lazy_init() {
  if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
    zle -N _fzf-history-widget 2>/dev/null || true
  else
    print -r -- "fzf: command not found. Install fzf to enable key-bindings/completions."
    return 1
  fi
}

# Run `fzf` binary => init then tail-call
fzf() {
  unfunction fzf 2>/dev/null || true
  _fzf_lazy_init || return $?
  command fzf "$@"
}

# Ctrl-R history => init then invoke widget
_fzf_lazy_history() {
  _fzf_lazy_init || return $?
  zle _fzf-history-widget
}
zle -N _fzf_lazy_history
bindkey '^R' _fzf_lazy_history

# Optional: one-shot hook to init on first completion-menu open
_fzf_lazy_complete_once() { _fzf_lazy_init; }
zle -N _fzf_lazy_complete_once

# ----- zoxide (tiny cost; worth loading eagerly) -----
eval "$(zoxide init --cmd cd zsh)"

# ----- yazi helper (already lazy) -----
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# =========================
# zinit bootstrap + plugins
# =========================
# Auto-install zinit on first run if missing
if [[ ! -f ${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh ]]; then
  mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git \
    "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
fi
source "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh"

# OMZ plugins via snippets (no OMZ core)

# OMZ git plugin
zinit ice depth=1 wait'2' lucid
zinit snippet OMZP::git

# OMZ archlinux plugin
zinit ice depth=1 wait'2' lucid
zinit snippet OMZP::archlinux


# ---- Autosuggestions tune & load ----
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'    # adjust if too bright/dim

# Bind after plugin is sourced; keep load after prompt with wait
zinit ice lucid atload'\
  bindkey -M emacs "^F" autosuggest-accept; \
  bindkey -M viins "^F" autosuggest-accept; \
  bindkey -M emacs "^[[C" autosuggest-accept; \
  bindkey -M viins "^[[C" autosuggest-accept'
zinit light zsh-users/zsh-autosuggestions

# (then your highlighting plugin, later)

# zsh-autosuggestions (before highlighting)
# zinit ice lucid
# zinit light zsh-users/zsh-autosuggestions
# bindkey "^F" suggest-accept
# # Optional: make suggestions more visible
# # ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
#
# zsh-syntax-highlighting (MUST be last among UI plugins)
 zinit ice lucid
 zinit light zsh-users/zsh-syntax-highlighting

# Optional: extra completions (deferred)
 zinit ice lucid
 zinit light zsh-users/zsh-completions

# =========================
# Diagnostics (optional)
# =========================
# zmodload zsh/zprof   # then run `zprof` in a fresh shell
# After startup, run:   zinit times

source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
