if [[ -z "${DEVEL_ENV_PATH}" ]]; then
	readonly DEVEL_ENV_PATH="${HOME}/.local/share/pc-devel-env"
fi

if [[ -f "${DEVEL_ENV_PATH}/Linux/env.zsh" ]]; then
	source "${DEVEL_ENV_PATH}/Linux/env.zsh"
fi

function setup_path() {
	local user_paths=()
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function setup_environment() {
	setup_path

	if GPG_TTY="$(tty)"; then
		export GPG_TTY
	fi

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		export MANPAGER='nvim +Man!'
	fi

	[[ -s "${HOME}/.autojump/etc/profile.d/autojump.sh" ]] &&
		source "${HOME}/.autojump/etc/profile.d/autojump.sh"
}

function setup_config() {
	if [[ ! -d "${HOME}/.nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.nvim-config"
		pushd "${HOME}/.nvim-config" >/dev/null
		bash "${HOME}/.nvim-config/install.sh"
		popd >/dev/null
	fi
}

setup_environment
setup_config
