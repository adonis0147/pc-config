readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

if [[ -f "${PC_CONFIG_PATH}/Linux/env.zsh" ]]; then
	source "${PC_CONFIG_PATH}/Linux/env.zsh"
fi

function setup_path() {
	local user_paths=(
		"${HOME}/.local/bin"
		"${HOME}/.local/share/nvim/mason/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function setup_environment() {
	setup_path

	export LC_CTYPE='en_US.UTF-8'
	export TZ='Asia/Shanghai'

	if GPG_TTY="$(tty)"; then
		export GPG_TTY
	fi

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		# On Ubuntu: sudo apt install apparmor-utils && sudo aa-disable /usr/bin/man
		export MANPAGER='nvim +Man!'
	fi

	if [[ -s "${HOME}/.autojump/etc/profile.d/autojump.sh" ]]; then
		source "${HOME}/.autojump/etc/profile.d/autojump.sh"
	fi
}

function install_softwares() {
	if [[ ! -d "${HOME}/.autojump" ]]; then
		pushd /tmp >/dev/null
		rm -rf autojump
		git clone https://github.com/wting/autojump
		cd autojump
		python3 install.py
		popd >/dev/null
	fi
}

function setup_config() {
	if [[ ! -d "${HOME}/.config/nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.config/nvim-config"
		pushd "${HOME}/.config/nvim-config" >/dev/null
		bash "${HOME}/.config/nvim-config/install.sh"
		popd >/dev/null
	fi

	if command -v git &>/dev/null && [[ ! -L "${HOME}/.gitignore_global" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/gitignore_global" "${HOME}/.gitignore_global"
		git config --global core.excludesFile "${HOME}/.gitignore_global"
	fi
}

function install_sdkman() {
	if [[ ! -d "${HOME}/.sdkman" ]]; then
		curl -s "https://get.sdkman.io" | bash

		local content='[[ -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source ${HOME}/.sdkman/bin/sdkman-init.sh'
		if ! grep "${content//\[/\\[}" "${HOME}/.zshenv" &>/dev/null; then
			echo "${content}" >>"${HOME}/.zshenv"
		fi

		eval "${content}"
	fi
}

setup_environment
install_softwares
install_sdkman
setup_config
