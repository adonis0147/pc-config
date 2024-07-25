# # .bash_profile
# if [[ -f "${HOME}/.local/share/devel/bin/zsh" ]]; then
#     exec "${HOME}/.local/share/devel/bin/zsh" -l
# fi


### Zinit Setting

if dircolors_cmd="$(command -v gdircolors || command -v dircolors)"; then
    eval "$("${dircolors_cmd}")"
fi

# Load OMZ libraries
zstyle ':omz:lib:theme-and-appearance' gnu-ls yes

omz_libraries=(
    theme-and-appearance
    key-bindings
    history
    completion
    directories
    git
    grep
)

for library in "${omz_libraries[@]}"; do
    zinit snippet "OMZL::${library}.zsh"
done

# Load Git plugin from OMZ
zinit snippet OMZP::git
zinit cdclear -q # <- forget completions provided up to this moment


# Load powerlevel10k theme
zinit ice depth'1' # git clone depth
zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zinit light romkatv/zsh-defer

zinit ice blockf
zinit light zsh-users/zsh-autosuggestions

zinit wait lucid for \
    light-mode zdharma-continuum/fast-syntax-highlighting \
    light-mode zdharma-continuum/history-search-multi-word

zinit ice wait lucid cloneopts'' pullopts'' as'command' pick'bin/jenv' id-as \
    atclone'ln -snf "${HOME}/.local/share/zinit/plugins/jenv" "${HOME}/.jenv"' \
    atload'eval "$(jenv init -)"'
zinit light jenv/jenv

zinit ice wait lucid cloneopts'' pullopts'' pick'nvm.sh' id-as \
    atclone'ln -snf "${HOME}/.local/share/zinit/plugins/nvm" "${HOME}/.nvm"' \
    atload'source bash_completion'
zinit light nvm-sh/nvm


# Load programs
zinit ice from'gh-r' as'program' atclone'./fzf --zsh >init.zsh' src'init.zsh'
zinit light junegunn/fzf

zinit ice reset from'gh-r' as'program' completions='complete/_rg' \
    atclone'folder="$(find . -mindepth 1 -maxdepth 1 -type d -name "ripgrep-*")"; mv "${folder}"/* .; rmdir "${folder}"'
zinit light BurntSushi/ripgrep


# Completions
if command -v kubectl &>/dev/null; then
    if [[ ! -f "${HOME}/.local/share/completions/kubectl_completion" ]]; then
        mkdir -p "${HOME}/.local/share/completions"
        kubectl completion zsh >"${HOME}/.local/share/completions/kubectl_completion"
    fi
    zsh-defer source "${HOME}/.local/share/completions/kubectl_completion"
fi

if command -v minikube &>/dev/null; then
    if [[ ! -f "${HOME}/.local/share/completions/minikube_completion" ]]; then
        mkdir -p "${HOME}/.local/share/completions"
        minikube completion zsh >"${HOME}/.local/share/completions/minikube_completion"
    fi
    zsh-defer source "${HOME}/.local/share/completions/minikube_completion"
fi
