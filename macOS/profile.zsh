readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

declare -g macos_version
macos_version="$(sw_vers -productVersion)"
declare -g major_version
major_version="${macos_version%%.*}"

if [[ -f "${PC_CONFIG_PATH}/macOS/env.zsh" ]]; then
	source "${PC_CONFIG_PATH}/macOS/env.zsh"
fi

function change_homebrew_mirror() {
	local contents=(
		"export HOMEBREW_API_DOMAIN='https://mirrors.aliyun.com/homebrew-bottles/api'"
		"export HOMEBREW_BOTTLE_DOMAIN='https://mirrors.aliyun.com/homebrew/homebrew-bottles'"
	)

	local changed=false
	for content in "${contents[@]}"; do
		if ! grep "${content}" "${PC_CONFIG_PATH}/macOS/env.zsh" &>/dev/null; then
			echo -e "${content}" >>"${PC_CONFIG_PATH}/macOS/env.zsh"
			changed=true
		fi
	done

	if "${changed}"; then
		source "${PC_CONFIG_PATH}/macOS/env.zsh"
		brew update
	fi
}

function setup_path() {
	local user_paths=(
		"${HOMEBREW_PREFIX}/bin"
		"${HOMEBREW_PREFIX}/sbin"
		"${HOME}/.local/bin"
		"${HOME}/.local/sbin"
		"${HOME}/.local/share/nvim/mason/bin"
		"${HOME}/.jenv/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	local cellars=(
		curl
		gnu-getopt
		llvm
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

	if [[ -s "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh" ]]; then
		source "${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh"
	fi

	if command -v gtar >/dev/null; then
		alias tar='gtar'
	fi

	export MANPATH="${HOME}/.local/share/man:${MANPATH}"
}

function install_terminfo() {
	local ncurses="ncurses-6.5"
	pushd /tmp >/dev/null
	rm -rf "${ncurses}"
	curl -L "https://ftpmirror.gnu.org/ncurses/${ncurses}.tar.gz" -o - | tar -zxf -
	mkdir "${ncurses}/build"
	cd "${ncurses}/build"
	../configure --prefix="$(pwd)/ncurses" --disable-widec --with-default-terminfo-dir="${PC_CONFIG_PATH}/terminfo"
	make -j "$(nproc)"
	make install
	popd

	rm -rf "${HOME}/.terminfo"
	ln -snf "${PC_CONFIG_PATH}/terminfo" "${HOME}/.terminfo"
}

function setup_config() {
	if [[ ! -L "${HOME}/.config/wezterm/wezterm.lua" ]]; then
		mkdir -p "${HOME}/.config/wezterm"
		ln -snf "${PC_CONFIG_PATH}/config/wezterm.lua" "${HOME}/.config/wezterm/wezterm.lua"
	fi

	if [[ ! -d "${HOME}/.tmux/plugins/tpm" ]]; then
		git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
	fi

	if [[ ! -L "${HOME}/.tmux.conf" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/tmux.conf" "${HOME}/.tmux.conf"
	fi

	if [[ ! -d "${HOME}/.config/nvim-config" ]]; then
		git clone https://github.com/adonis0147/nvim-config "${HOME}/.config/nvim-config"
		pushd "${HOME}/.config/nvim-config" >/dev/null
		bash "${HOME}/.config/nvim-config/install.sh"
		popd >/dev/null
	fi

	if [[ ! -d "${PC_CONFIG_PATH}/terminfo" ]]; then
		install_terminfo
	fi

	if [[ ! -f "${HOME}/.pip/pip.conf" ]]; then
		mkdir -p "${HOME}/.pip"

		cat >"${HOME}/.pip/pip.conf" <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host = mirrors.aliyun.com
EOF
	fi
	export PIP_TRUSTED_HOST='mirrors.aliyun.com'

	if [[ ! -L "${HOME}/.gitignore_global" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/gitignore_global" "${HOME}/.gitignore_global"
		git config --global core.excludesFile "${HOME}/.gitignore_global"
	fi
}

function install_cellars() {
	local cellars=(
		autojump
		bash
		ccache
		cmake
		coreutils
		curl
		git
		gnu-getopt
		gnu-tar
		htop
		lld
		llvm
		ninja
		python
		squid
		tmux
		wget
	)
	if [[ "${major_version}" -ge 13 ]]; then
		cellars+=(
			neovim
		)
	fi

	for cellar in "${cellars[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/opt/${cellar}" ]]; then
			brew install --formula "${cellar}"
		fi
	done
}

function install_casks() {
	local casks=(
		font-sf-mono
		karabiner-elements
		keka
		snipaste
		stolendata-mpv
		wezterm
	)
	if [[ "${major_version}" -ge 13 ]]; then
		casks+=(
			scroll-reverser
		)
	fi

	for cask in "${casks[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/Caskroom/${cask}" ]]; then
			brew install --cask "${cask}"
		fi
	done
}

function install_rye() {
	export PATH="${HOME}/.rye/shims:${PATH}"

	if [[ ! -d "${HOME}/.rye" ]]; then
		curl -sSL https://rye-up.com/get | RYE_INSTALL_OPTION="--yes" bash

		rye config --set-bool behavior.use-uv=true
	fi

	alias pip='python -m pip'
	alias pip3='python3 -m pip'
}

function install_sdkman() {
	if [[ ! -d "${HOME}/.sdkman" ]]; then
		curl -s "https://get.sdkman.io" | sed '/^sdkman_init_snippet/,/^)/d' | bash
	fi
}

function unset_variables() {
	unset macos_version
	unset major_version
}

setup_environment
change_homebrew_mirror
install_cellars
install_casks
install_rye
install_sdkman
setup_config
unset_variables

source "${PC_CONFIG_PATH}/macOS/utils.zsh"
