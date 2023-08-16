if [[ -z "${DEVEL_ENV_PATH}" ]]; then
	readonly DEVEL_ENV_PATH="${HOME}/.local/share/pc-devel-env"
fi

if [[ -f "${DEVEL_ENV_PATH}/env.zsh" ]]; then
	source "${DEVEL_ENV_PATH}/env.zsh"
fi

function change_homebrew_mirror() {
	pushd "$(brew --repo)"
	git remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
	popd

	brew update
	local content='export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles'
	if ! grep "${content}" "${DEVEL_ENV_PATH}/env.zsh" &>/dev/null; then
		echo -e "${content}" >>"${DEVEL_ENV_PATH}/env.zsh"
	fi

	source "${DEVEL_ENV_PATH}/env.zsh"
}

function setup_path() {
	local user_paths=(
		"${HOMEBREW_PREFIX}/bin"
		"${HOMEBREW_PREFIX}/sbin"
		"${HOME}/.local/share/nvim/mason/bin"
		"${HOME}/.jenv/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	local cellars=(
		tmux
		nvim
		llvm
		python@3
	)
	for cellar in "${cellars[@]}"; do
		PATH="${HOMEBREW_PREFIX}/opt/${cellar}/bin:${PATH}"
	done

	export PATH
}

function setup_environment() {
	setup_path

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		export MANPAGER='nvim +Man!'
	fi

	[[ -s "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh" ]] && \
		source "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh"
}

function setup_config() {
	if [[ ! -h "${HOME}/.alacritty.yml" ]]; then
		ln -snf "${DEVEL_ENV_PATH}/config/alacritty.yml" "${HOME}/.alacritty.yml"
	fi

	if [[ ! -h "${HOME}/.tmux.conf" ]]; then
		ln -snf "${DEVEL_ENV_PATH}/config/tmux.conf" "${HOME}/.tmux.conf"
	fi

	if [[ ! -d "${HOME}/.nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.nvim-config"
		pushd "${HOME}/.nvim-config" >/dev/null
		bash "${HOME}/.nvim-config/install.sh"
		popd >/dev/null
	fi
}

function install_cellars() {
	local cellars=(
		autojump
		llvm
		neovim
		python
		tmux
		coreutils
		git
	)

	for cellar in "${cellars[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/opt/${cellar}" ]]; then
			brew install "${cellar}"
		fi
	done
}

function install_casks() {
	local CASKS=(
		alacritty
		karabiner-elements
		keka
		mpv
		scroll-reverser
		snipaste
		texstudio
	)

	for cask in "${CASKS[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/Caskroom/${cask}" ]]; then
			brew install --cask "${cask}"
		fi
	done
}

setup_environment
setup_config
