function setup_environment() {
	local user_paths=(
		'/snap/bin'
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function install_packages() {
	local installed
	installed="$(apt list --installed)"
	local packages=(
		'fzf'
	)

	for package in "${packages[@]}"; do
		if ! echo "${installed}" | grep -E "^${package}/" &>/dev/null; then
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

setup_environment
install_packages
install_snaps
