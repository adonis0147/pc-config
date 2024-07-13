readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

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
		"${HOME}/.local/share/nvim/mason/bin"
		"${HOME}/.jenv/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	local cellars=(
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
	rm -f "${HOME}/.terminfo/61/{alacritty,alacritty-direct}"
	ln -snf ${HOMEBREW_PREFIX}/Caskroom/alacritty/*/Alacritty.app/Contents/Resources/61/* "${HOME}/.terminfo/61"
}

function setup_config() {
	if [[ ! -L "${HOME}/.alacritty.toml" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/alacritty.toml" "${HOME}/.alacritty.toml"
	fi

	if [[ ! -L "${HOME}/.wezterm.lua" ]]; then
		ln -snf "${PC_CONFIG_PATH}/config/wezterm.lua" "${HOME}/.wezterm.lua"
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

	if [[ ! -f "${HOME}/.fzf.zsh" ]]; then
		cat >"${HOME}/.fzf.zsh" <<EOF
# Auto-completion
# ---------------
source "\${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"

# Key bindings
# ------------
source "\${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
bindkey "^R" history-search-multi-word
EOF
	fi

	if [[ ! -f "${HOME}/.pip/pip.conf" ]]; then
		mkdir -p "${HOME}/.pip"

		cat >"${HOME}/.pip/pip.conf" <<EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
	fi
}

function install_cellars() {
	local cellars=(
		autojump
		bash
		ccache
		cmake
		coreutils
		fzf
		git
		gnu-getopt
		gnu-tar
		htop
		llvm
		neovim
		ninja
		npm
		python
		ripgrep
		tmux
		wget
	)

	for cellar in "${cellars[@]}"; do
		if [[ ! -d "${HOMEBREW_PREFIX}/opt/${cellar}" ]]; then
			brew install "${cellar}"
		fi
	done
}

function install_casks() {
	local macos_version
	macos_version="$(sw_vers -productVersion)"
	local major_version
	major_version="${macos_version%%.*}"

	local casks=(
		alacritty
		karabiner-elements
		keka
		snipaste
		stolendata-mpv
		wezterm
	)
	if [[ "${major_version}" -ge 13 ]]; then
		casks+=(scroll-reverser)
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
		curl -sSf https://rye-up.com/get | RYE_INSTALL_OPTION="--yes" bash

		rye config --set-bool behavior.use-uv=true
	fi

	alias pip='python -m pip'
	alias pip3='python3 -m pip'
}

setup_environment
change_homebrew_mirror
install_cellars
install_casks
install_rye
setup_config
