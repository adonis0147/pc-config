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
    key-bindings
    history
)

for library in "${omz_libraries[@]}"; do
    zinit snippet "OMZL::${library}.zsh"
done

zinit wait lucid for \
    'OMZL::theme-and-appearance.zsh' \
    'OMZL::completion.zsh' \
    'OMZL::directories.zsh' \
    'OMZL::git.zsh' \
    'OMZL::grep.zsh'

# Load Git plugin from OMZ
zinit ice wait lucid \
    atload'zinit cdclear -q' # <- forget completions provided up to this moment
zinit snippet OMZP::git


# Load plugins
zinit light romkatv/zsh-defer

# Load powerlevel10k theme
PS1=''
zinit ice wait'!' lucid nocd \
    atload'[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh; _p9k_precmd' \
    depth'1' # git clone depth
zinit light romkatv/powerlevel10k

zinit ice wait lucid blockf atload'_zsh_autosuggest_start'
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
zinit ice wait lucid from'gh-r' as'program' \
    atclone'./fzf --zsh >init.zsh; echo -e "\nbindkey \"^R\" history-search-multi-word" >>init.zsh' src'init.zsh' \
    atpull'%atclone'
zinit light junegunn/fzf

zinit ice wait lucid from'gh-r' as'program' completions='complete/_rg' \
    atclone'folder="$(find . -mindepth 1 -maxdepth 1 -type d -name "ripgrep-*")"; mv "${folder}"/* .; rmdir "${folder}"' \
    atpull'%atclone'
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
