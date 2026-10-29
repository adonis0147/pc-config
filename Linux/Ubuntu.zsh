function setup_environment() {
	local llvm_version='22'
	local user_paths=(
		'/snap/bin'
		"/usr/lib/llvm-${llvm_version}/bin"
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function install_packages() {
	local installed
	installed="$(apt list --installed 2>/dev/null)"
	local packages=(
		'autoconf'
		'build-essential'
		'ccache'
		'cmake'
		'chrony'
		'gdb'
		'libtool-bin'
		'ninja-build'
		'openconnect'
		'pkg-config'
		'unzip'
		'zip'
	)

	for package in "${packages[@]}"; do
		if ! echo "${installed}" | grep -E "^${package//+/\\+}/" &>/dev/null; then
			sudo DEBIAN_FRONTEND=noninteractive apt install --yes "${package}"
		fi
	done
}

function install_snaps() {
	local installed
	installed="$(snap list | awk '{ if (NR > 1) { print $1} }')"
	local classic_snaps=(
		'nvim'
	)

	for snap in "${classic_snaps[@]}"; do
		if ! echo "${installed}" | grep -E "^${snap}$" &>/dev/null; then
			sudo snap install "${snap}" --classic
		fi
	done
}

function setup_config() {
	if ! [[ -f /etc/chrony/conf.d/resume.conf ]]; then
		echo 'makestep 1.0 -1' | sudo tee /etc/chrony/conf.d/resume.conf >/dev/null
		sudo systemctl enable --now chrony
		sudo systemctl restart chrony
	fi
}

setup_environment
install_packages
install_snaps
setup_config
