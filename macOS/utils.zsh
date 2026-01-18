source "${PC_CONFIG_PATH}/common/utils.zsh"

function install_neovim() {
	echo -e "\033[32;1m======== Install Neovim ========\033[0m"

	local url='https://api.github.com/repos/neovim/neovim/releases/latest'
	local latest
	local current
	local cmd

	if [[ -n "${GITHUB_TOKEN}" ]]; then
		cmd="curl -H 'Authorization: Bearer ${GITHUB_TOKEN}' -s ${url}"
	else
		cmd="curl -s ${url}"
	fi

	latest="$(eval "${cmd}" | python -c "import json; import sys; print(json.load(sys.stdin)['tag_name'])")"

	if [[ -z "${latest}" ]]; then
		return
	fi

	current="$(nvim -version 2>/dev/null | sed -n 's/NVIM \(.*\)/\1/p')"

	if [[ "${current}" != "${latest}" ]]; then
		local bin="${HOME}/.local/bin"
		local share="${HOME}/.local/share"
		local prefix="${HOME}/.local/opt/neovim"
		local download_url

		rm -rf "${prefix}"

		mkdir -p "${bin}"
		mkdir -p "${prefix}"

		download_url="https://github.com/neovim/neovim/releases/download/${latest}/nvim-macos-$(uname -m).tar.gz"
		curl -L "${download_url}" -o - | tar -C "${prefix}" --strip-components=1 -zxf -

		ln -snf "${prefix}/bin"/* "${bin}"/

		local dir
		for dir in $(find "${prefix}/share/man" -mindepth 1 -maxdepth 1); do
			local destination
			destination="${share}/man/$(basename "${dir}")"
			mkdir -p "${destination}"
			ln -snf "${dir}"/* "${destination}"/
		done
	else
		echo -e "\033[35;1mThe version of Neovim is latest.\033[0m"
	fi
}

function setup_squid() {
	local https_proxy_server="${1}"
	local port="${2}"
	local user="${3}"
	local password="${4}"
	local config="${PC_CONFIG_PATH}/config/squid.conf"

	sed "/^never_direct/i \\
cache_peer ${https_proxy_server} parent ${port} 0 no-query no-digest round-robin login=${user}:${password} ssl \\
" "${config}" >"${HOMEBREW_PREFIX}/etc/$(basename "${config}")"
}

function setup_mihomo() {
	local url="${1}"
	local ui_host="${2}"
	local config="${PC_CONFIG_PATH}/config/mihomo.yaml"
	local service_status

	if [[ -z "${ui_host}" ]]; then
		ui_host='127.0.0.1'
	fi

	sed "{
		s|\(external-controller: \).*|\1\"${ui_host}:9090\"|
		s|\(url: \)\"\"|\1\"${url}\"|
	}" "${config}" >"${HOMEBREW_PREFIX}/etc/mihomo/config.yaml"

	service_status="$(brew services | grep mihomo | awk '{print $2}')"
	if [[ "${service_status}" == 'none' ]]; then
		brew services start mihomo
	fi
}

function enable_wifi_web_proxy() {
	local domain=${1:-127.0.0.1}
	local port=${2:-7897}
	local service=${3-Wi-Fi}

	networksetup -setwebproxy "${service}" "${domain}" "${port}"
	networksetup -setsecurewebproxy "${service}" "${domain}" "${port}"
}

function disable_wifi_web_proxy() {
	local service=${1:-Wi-Fi}

	networksetup -setwebproxystate "${service}" off
	networksetup -setsecurewebproxystate "${service}" off
}

function update_all() {
	local macos_version
	macos_version="$(sw_vers -productVersion)"
	local major_version="${macos_version%%.*}"

	update_zinit
	update_uv

	if [[ "${major_version}" -ge 13 ]]; then
		update_node
	fi

	update_rust
	update_sdk
	install_neovim
}
