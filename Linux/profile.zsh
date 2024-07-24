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

	if [[ ! -f "${HOME}/.fzf.zsh" ]]; then
		cat >"${HOME}/.fzf.zsh" <<EOF
FZF_PREFIX='/usr/share/doc/fzf/examples'

# Auto-completion
# ---------------
[[ ! -f "\${FZF_PREFIX}/completion.zsh" ]] || source "\${FZF_PREFIX}/completion.zsh"

# Key bindings
# ------------
if [[ -f "\${FZF_PREFIX}/key-bindings.zsh" ]]; then
	source "\${FZF_PREFIX}/key-bindings.zsh"
	bindkey "^R" history-search-multi-word
fi

unset FZF_PREFIX
EOF
	fi
}

function setup_for_specific_os() {
	local file="${PC_CONFIG_PATH}/Linux/${OS_DISTRIBUTOR}.zsh"
	if [[ -f "${file}" ]]; then
		source "${file}"
	fi
}

setup_environment
install_softwares
setup_config
setup_for_specific_os
