function setup_environment() {
	local user_paths=(
		'/snap/bin'
		'/usr/lib/llvm-18/bin'
	)
	for p in "${user_paths[@]}"; do
		PATH="${p}:${PATH}"
	done

	export PATH
}

function install_packages() {
	if [[ ! -f "/etc/apt/trusted.gpg.d/apt.llvm.org.asc" ]]; then
		curl -q https://apt.llvm.org/llvm-snapshot.gpg.key -o - | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
		sudo apt update
	fi

	local installed
	installed="$(apt list --installed 2>/dev/null)"
	local llvm_version='18'
	local packages=(
		"clang-${llvm_version}"
		"clang-format-${llvm_version}"
		"clang-tidy-${llvm_version}"
		"clang-tools-${llvm_version}"
		"clangd-${llvm_version}"
		"libc++-${llvm_version}-dev"
		"libc++abi-${llvm_version}-dev"
		"lld-${llvm_version}"
		"lldb-${llvm_version}"
		'build-essential'
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
