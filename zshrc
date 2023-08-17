# # .bash_profile
# if [[ -f "${HOME}/devel/bin/zsh" ]]; then
#     exec "${HOME}/devel/bin/zsh" -l
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
zinit ice depth"1" # git clone depth
zinit light romkatv/powerlevel10k

zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zdharma-continuum/history-search-multi-word
zinit light romkatv/zsh-defer

if [[ "$(uname -s)" == 'Darwin' ]]; then
    zinit ice as'command' pick'bin/jenv' id-as \
        atclone'ln -snf "${HOME}/.local/share/zinit/plugins/jenv" "${HOME}/.jenv"'
    zinit light @jenv/jenv

    zsh-defer eval "$(jenv init -)"
fi

autoload -Uz compinit
compinit

if command -v kubectl &>/dev/null; then
    source <(kubectl completion zsh)
fi

if command -v minikube &>/dev/null; then
    source <(minikube completion zsh)
fi

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
