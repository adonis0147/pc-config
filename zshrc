# # .bash_profile
# export TERM="${TERM/-256color/}-256color"
#
# if [[ -f "${HOME}/.local/share/devel/bin/zsh" ]] && [[ "${TERM}" =~ .*-256color ]]; then
#     exec "${HOME}/.local/share/devel/bin/zsh" -l
# fi

function setup() {
	### Zinit Setting

	local dircolors_cmd
	if dircolors_cmd="$(command -v gdircolors || command -v dircolors)"; then
		eval "$("${dircolors_cmd}")"
	fi

	# Load OMZ libraries
	zstyle ':omz:lib:theme-and-appearance' gnu-ls yes

	local omz_libraries=(
		key-bindings
		history
	)

	local library
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

	zstyle ':plugin:history-search-multi-word' clear-on-cancel 'yes'
	zinit wait lucid for \
		light-mode zdharma-continuum/fast-syntax-highlighting \
		light-mode zdharma-continuum/history-search-multi-word

	# Load SDKMAN!
	if [[ -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
		zinit ice wait lucid
		zinit snippet "${HOME}/.sdkman/bin/sdkman-init.sh"
	fi

	zinit ice wait lucid cloneopts'' pullopts'' as'command' pick'bin/jenv' id-as \
		atclone'ln -snf "${HOME}/.local/share/zinit/plugins/jenv" "${HOME}/.jenv"' \
		atload'eval "$(jenv init -)"'
	zinit light jenv/jenv

	zinit ice wait lucid cloneopts'' pullopts'' pick'nvm.sh' id-as \
		atclone'ln -snf "${HOME}/.local/share/zinit/plugins/nvm" "${HOME}/.nvm"'
	zinit light nvm-sh/nvm

	# Load programs
	zinit ice wait lucid from'gh-r' as'program' \
		atclone'./fzf --zsh >init.zsh; echo -e "\nbindkey \"^R\" history-search-multi-word" >>init.zsh' src'init.zsh' \
		atpull'%atclone'
	zinit light junegunn/fzf

	zinit ice wait lucid from'gh-r' as'program' completions'complete/_rg' \
		atclone'folder="$(find . -mindepth 1 -maxdepth 1 -type d -name "ripgrep-*")"; mv "${folder}"/* .; rmdir "${folder}"' \
		atpull'%atclone'
	zinit light BurntSushi/ripgrep

	if [[ "$(uname -a)" =~ Darwin.*x86_64 ]]; then
		zinit ice wait lucid from'gh-r' as'program' \
			atclone'folder="$(find . -mindepth 1 -maxdepth 1 -type d -name "ccache-*")"; mv "${folder}"/* .; rmdir "${folder}"' \
			atpull'%atclone'
		zinit light ccache/ccache
	fi

	zinit ice wait lucid from'gh-r' as'program' \
		atclone'mv tree-sitter-* tree-sitter; chmod a+x tree-sitter; if command -v relocate &>/dev/null; then relocate tree-sitter; fi' \
		atpull'%atclone'
	zinit light tree-sitter/tree-sitter

	# Completions
	local COMPLETIONS_PATH="${HOME}/.local/share/completions"

	if [[ ! -d "${COMPLETIONS_PATH}" ]]; then
		mkdir -p "${COMPLETIONS_PATH}"
	fi

	if command -v kubectl &>/dev/null; then
		if [[ ! -f "${COMPLETIONS_PATH}/_kubectl" ]]; then
			kubectl completion zsh >"${COMPLETIONS_PATH}/_kubectl"
		fi
		zinit ice wait lucid as'completion'
		zinit snippet "${COMPLETIONS_PATH}/_kubectl"
	fi

	if command -v minikube &>/dev/null; then
		if [[ ! -f "${COMPLETIONS_PATH}/_minikube" ]]; then
			minikube completion zsh >"${COMPLETIONS_PATH}/_minikube"
		fi
		zinit ice wait lucid as'completion'
		zinit snippet "${COMPLETIONS_PATH}/_minikube"
	fi

	if command -v uv &>/dev/null; then
		if [[ ! -f "${COMPLETIONS_PATH}/uv_completion" ]]; then
			uv generate-shell-completion zsh >"${COMPLETIONS_PATH}/uv_completion"
		fi
	fi

	if [[ ! -f "${COMPLETIONS_PATH}/completions" ]]; then
		local completion_files=(
			'${HOME}/.nvm/bash_completion'
			"${COMPLETIONS_PATH}/uv_completion"
		)
		local file
		for file in "${completion_files[@]}"; do
			echo "[[ -f \"${file}\" ]] && source \"${file}\"" >>"${COMPLETIONS_PATH}/completions"
		done
	fi

	zinit wait lucid blockf for \
		atload'zicompinit; zicdreplay; _zsh_autosuggest_start' zsh-users/zsh-autosuggestions \
		as'null' atload' source completions' "${COMPLETIONS_PATH}"
}

setup
