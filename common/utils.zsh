function install_rust() {
	if ! bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- \
		-y --no-modify-path -c rust-src,rust-analyzer; then
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

function install_uv() {
	if [[ -x "${HOME}/.local/bin/uv" ]]; then
		return
	fi

	curl -LsSf https://astral.sh/uv/install.sh | bash

	if command -v uv &>/dev/null; then
		export UV_PYTHON_INSTALL_MIRROR='https://registry.npmmirror.com/-/binary/python-build-standalone'
		uv python install default

		local python3="$(find "${HOME}/.local/bin" -name 'python3.*')"
		if [[ -n "${python3}" ]]; then
			ln -snf "${python3}" "${HOME}/.local/bin/python3"
			ln -snf python3 "${HOME}/.local/bin/python"
		fi
	fi
}

function update_uv() {
	echo -e "\033[32;1m======== Update uv ========\033[0m"

	if command -v uv &>/dev/null; then
		if [[ -n "${GITHUB_TOKEN}" ]]; then
			uv self update --token "${GITHUB_TOKEN}"
		else
			uv self update
		fi
		uv python upgrade
	else
		echo -e "\033[35;1muv is not installed.\033[0m"
	fi
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
	local content
	if ! content="$(echo n | sdk upgrade)"; then
		echo "${content}"
		return
	fi

	echo "${content}"
	content="$(echo "${content}" | sed '1,/Available defaults/d; /^$/d; $d' | awk '{gsub(/\033\[[0-9]+(;[0-9]+)*m/, "", $0); print $0}')"

	while read -r candidate; do
		echo "candidate: ${candidate}"
		if [[ -z "${candidate}" ]]; then
			continue
		fi

		echo Y | sdk upgrade "${candidate}"
	done < <(echo "${content}" | awk '{if ($1 != "java") print $1}')

	if [[ ! -d "${HOME}/.sdkman/candidates/java" ]]; then
		return
	fi

	if ! content="$(sdk list java 2>&1)"; then
		echo "${content}"
		return
	fi
	if [[ -z "${content//[[:space:]]/}" ]] || echo "${content}" | grep 'INTERNET NOT REACHABLE!' &>/dev/null; then
		echo "${content}"
		return
	fi

	local latest
	while read -r candidate; do
		candidate="$(basename "${candidate}")"
		local major="${candidate%%.*}"
		local dist="${candidate/*-}"
		latest="$(echo "${content}" | grep -E "\| ${major}\..*-${dist}" | awk '{if (NR == 1) print $NF}')"
		if [[ -z "${latest}" ]]; then
			echo "Unable to determine the latest java ${major}-${dist} version; keeping ${candidate}."
			continue
		fi

		if [[ "${latest}" != "${candidate}" ]]; then
			if [[ "$(jenv global)" =~ "${major}" ]]; then
				if ! echo Y | sdk install java "${latest}"; then
					continue
				fi
			else
				if ! echo n | sdk install java "${latest}"; then
					continue
				fi
			fi
			if [[ ! -x "${HOME}/.sdkman/candidates/java/${latest}/bin/java" ]]; then
				echo "java ${latest} was not installed correctly; keeping ${candidate}."
				continue
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

function mihomo_test_latency() {
	local proxy_group="${1:-自动选择}"
	local url='https://www.gstatic.com/generate_204'

	curl -s "http://127.0.0.1:9090/group/${proxy_group}/delay?url=${url}&timeout=5000" |
		python3 -c '
import json, sys
data = json.load(sys.stdin)
for name, latency in sorted(data.items(), key=lambda x: x[1], reverse=True):
    print(f"{latency:5}ms\t{name}")
'
}

function mihomo_choose_proxy() {
	local node="${1}"
	local proxy_group="${2:-自动选择}"

	curl -X PUT "http://127.0.0.1:9090/proxies/${proxy_group}" \
		-H 'Content-Type: application/json' \
		-d "{\"name\": \"${node}\"}"
}
