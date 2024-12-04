function install_rust() {
	if ! bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- \
		-y --no-modify-path -c rust-src rust-analyzer; then
		return
	fi

	local content='[[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env" '
	if ! grep "${content}" "${HOME}/.zshenv" &>/dev/null; then
		echo "\n${content}" >>"${HOME}/.zshenv"
		eval "${content}"
	fi
}

function update_rust() {
	echo -e "\033[32;1m======== Update Rust ========\033[0m"

	if command -v rustup &>/dev/null; then
		rustup update
	else
		echo -e "\033[35;1mRust is not installed.\033[0m"
	fi
}

function update_zinit() {
	echo -e "\033[32;1m======== Update Zinit ========\033[0m"

	zinit update
}

function install_rye() {
	export PATH="${HOME}/.rye/shims:${PATH}"

	if [[ ! -d "${HOME}/.rye" ]]; then
		curl -sSL https://rye-up.com/get | RYE_INSTALL_OPTION="--yes" bash

		rye config --set-bool behavior.use-uv=true
		rye config --set default.toolchain=cpython@3
	fi

	alias pip='python -m pip'
	alias pip3='python3 -m pip'
}

function update_rye() {
	echo -e "\033[32;1m======== Update Rye ========\033[0m"

	if command -v rye &>/dev/null; then
		rye self update
	else
		echo -e "\033[35;1mRye is not installed.\033[0m"
	fi
	rye fetch
}

function update_node() {
	echo -e "\033[32;1m======== Update Node ========\033[0m"

	nvm install node --reinstall-packages-from=node
}

function install_sdkman() {
	if [[ ! -d "${HOME}/.sdkman" ]]; then
		curl -s "https://get.sdkman.io" | sed '/^sdkman_init_snippet/,/^)/d' | bash
	fi
}

function update_sdk() {
	echo -e "\033[32;1m======== Update SDK ========\033[0m"

	local candidate
	local content="$(echo n | sdk upgrade | sed '/^$/d; /Available defaults/d; $d' | awk '{gsub(/\033\[[0-9]+(;[0-9]+)*m/, "", $0); print $0}')"
	while read -r candidate; do
		echo Y | sdk upgrade "${candidate}"
	done < <(echo "${content}" | awk '{if ($1 != "java") print $1}')

	if [[ ! -d "${HOME}/.sdkman/candidates/java" ]]; then
		return
	fi

	local content="$(sdk list java)"
	while read -r candidate; do
		candidate="$(basename "${candidate}")"
		local major="${candidate%%.*}"
		local dist="${candidate/*-}"
		local latest="$(echo "${content}" | grep -E "${major}.*-${dist}" | awk '{if (NR == 1) print $NF}')"

		if [[ "${latest}" != "${candidate}" ]]; then
			if [[ "$(jenv global)" =~ "${major}" ]]; then
				echo Y | sdk install java "${latest}"
			else
				echo n | sdk install java "${latest}"
			fi
			sdk uninstall java "${candidate}"

			local link
			local version
			while read -r link; do
				version="$(basename "${link}")"
				if ls -l "${link}" | grep "${candidate}" &>/dev/null; then
					jenv remove "${version}"
				fi
			done < <(find "${HOME}/.jenv/versions" -mindepth 1 -maxdepth 1)

			jenv add "${HOME}/.sdkman/candidates/java/${latest}"
		fi
	done < <(find "${HOME}/.sdkman/candidates/java" -mindepth 1 -maxdepth 1 ! -name "current")
}
