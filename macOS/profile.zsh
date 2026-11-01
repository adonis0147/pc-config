readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

declare -g macos_version
macos_version="$(sw_vers -productVersion)"
declare -g major_version
major_version="${macos_version%%.*}"

if [[ -f "${PC_CONFIG_PATH}/macOS/env.zsh" ]]; then
	source "${PC_CONFIG_PATH}/macOS/env.zsh"
fi

export PACKAGE_MANAGER="${PACKAGE_MANAGER:-homebrew}"

function setup_path() {
	local user_paths=()
	if [[ "${PACKAGE_MANAGER}" == 'homebrew' ]]; then
		user_paths=("${HOMEBREW_PREFIX}/bin" "${HOMEBREW_PREFIX}/sbin")
	elif [[ "${PACKAGE_MANAGER}" == 'macports' ]]; then
		user_paths=('/opt/local/bin' '/opt/local/sbin')
	fi
	user_paths+=(
		"${HOME}/.local/bin"
		"${HOME}/.local/sbin"
		"${HOME}/.local/share/nvim/mason/bin"
		"${HOME}/.jenv/bin"
		"${GOBIN}"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	if [[ "${PACKAGE_MANAGER}" == 'homebrew' ]]; then
		local cellars=(
			curl
			gnu-getopt
			llvm
		)
		for cellar in "${cellars[@]}"; do
			PATH="${HOMEBREW_PREFIX}/opt/${cellar}/bin:${PATH}"
		done
	fi

	export PATH
}

function setup_environment() {
	export GOPATH="${HOME}/.local/share/go"
	export GOBIN="${GOPATH}/bin"

	setup_path

	if command -v nvim >/dev/null; then
		export EDITOR='nvim'
		export MANPAGER='nvim +Man!'
	fi

	local autojump
	if [[ "${PACKAGE_MANAGER}" == 'homebrew' ]]; then
		autojump="${HOMEBREW_PREFIX}/opt/autojump/etc/profile.d/autojump.sh"
	elif [[ "${PACKAGE_MANAGER}" == 'macports' ]]; then
		autojump='/opt/local/etc/profile.d/autojump.sh'
	fi
	[[ -s "${autojump}" ]] && source "${autojump}"

	if command -v gtar >/dev/null; then
		alias tar='gtar'
	fi

	export MANPATH="${HOME}/.local/share/man:${MANPATH}"

	if command -v uv >/dev/null; then
		export UV_PYTHON_INSTALL_MIRROR='https://registry.npmmirror.com/-/binary/python-build-standalone'
	fi
}

function install_terminfo() {
	local ncurses="ncurses-6.6"
	pushd /tmp >/dev/null
	rm -rf "${ncurses}"
	curl -L "https://ftpmirror.gnu.org/ncurses/${ncurses}.tar.gz" -o - | tar -zxf -
	mkdir "${ncurses}/build"
	cd "${ncurses}/build"
	../configure --prefix="$(pwd)/ncurses" --disable-widec --with-default-terminfo-dir="${PC_CONFIG_PATH}/terminfo"
	make -j "$(sysctl -n hw.ncpu)"
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
		mkdir "${PC_CONFIG_PATH}/terminfo"
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

	if [[ ! -L "${HOME}/.ideavimrc" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/ideavimrc" "${HOME}/.ideavimrc"
	fi

	local opencode_configs=('opencode.json' 'tui.json')
	for config in "${opencode_configs[@]}"; do
		if [[ ! -L "${HOME}/.config/opencode/${config}" ]]; then
			mkdir -p "${HOME}/.config/opencode"
			ln -snf "${PC_CONFIG_PATH}/config/opencode/${config}" "${HOME}/.config/opencode/${config}"
		fi
	done

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
		jq
		lld
		llvm
		mihomo
		mpv
		neovim
		ninja
		python
		tmux
		wget
	)

	for cellar in "${cellars[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/opt/${cellar}" ]]; then
			brew install --formula --yes "${cellar}"
		fi
	done
}

function install_casks() {
	local casks=(
		font-sf-mono
		karabiner-elements
		keka
		snipaste
		wezterm
	)
	if [[ "${major_version}" -ge 13 ]]; then
		casks+=(
			scroll-reverser
		)
	fi

	for cask in "${casks[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/Caskroom/${cask}" ]]; then
			"${HOMEBREW_PREFIX}/bin/brew" install --cask --yes "${cask}"
		fi
	done
}

function install_ports() {
	local installed
	installed="$(port installed | sed -n '2,$p' | awk '{print $1}')"

	local python_version='3.15'
	local llvm_version='23'

	local ports=(
		mihomo # sudo port -N -s install mihomo +logging
		bash
		coreutils
		gnutar
		util-linux
		ccache
		cmake
		ninja
		tmux
		"clang-${llvm_version}"
		"lldb-${llvm_version}"
		"python${python_version//./}"
		autojump
		curl
		git
		go
		htop
		jq
		neovim
		wget
	)

	for port in "${ports[@]}"; do
		if ! printf '%s\n' "${installed}" | grep -qxF "${port}"; then
			sudo port -N install "${port}"
		fi
	done

	if [[ ! /opt/local/bin/python3 -ef "/opt/local/bin/python${python_version}" ]]; then
		sudo port select --set python3 "python${python_version//./}"
	fi
	if [[ ! /opt/local/bin/clang -ef "/opt/local/bin/clang-mp-${llvm_version}" ]]; then
		sudo port select --set clang "mp-clang-${llvm_version}"
	fi
	if [[ ! /opt/local/bin/lldb -ef "/opt/local/bin/lldb-mp-${llvm_version}" ]]; then
		sudo port select --set lldb "mp-lldb-${llvm_version}"
	fi
}

function install_packages() {
	if [[ "${PACKAGE_MANAGER}" == 'homebrew' ]]; then
		install_cellars
	elif [[ "${PACKAGE_MANAGER}" == 'macports' ]]; then
		install_ports
	fi
	install_casks
}

function unset_variables() {
	unset macos_version
	unset major_version
}

source "${PC_CONFIG_PATH}/macOS/utils.zsh"

setup_environment
install_packages
install_uv
install_sdkman
setup_config
unset_variables
