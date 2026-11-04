source "${PC_CONFIG_PATH}/common/utils.zsh"

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
	local config_content service_status

	if [[ -z "${ui_host}" ]]; then
		ui_host='127.0.0.1'
	fi

	config_content=$(sed "{
		s|\(external-controller: \).*|\1\"${ui_host}:9090\"|
		s|\(url: \)\"\"|\1\"${url}\"|
	}" "${config}")

	if [[ "${PACKAGE_MANAGER}" == 'homebrew' ]]; then
		printf '%s\n' "${config_content}" >"${HOMEBREW_PREFIX}/etc/mihomo/config.yaml"
		service_status="$(brew services | grep mihomo | awk '{print $2}')"
		if [[ "${service_status}" == 'none' ]]; then
			brew services start mihomo
		fi
	else
		sudo mkdir -p /opt/local/etc/mihomo
		printf '%s\n' "${config_content}" | sudo tee /opt/local/etc/mihomo/config.yaml >/dev/null
		sudo port load mihomo
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

function setup_macports_proxy() {
	local url="${1%/}"
	local proxy="${url#http://}"
	local config=/opt/local/etc/macports/macports.conf
	local content
	content=$(sudo sed -E \
		'/^[[:space:]]*#?[[:space:]]*proxy_(override_env|http|https|rsync)([[:space:]]|$)/d' "${config}") || return $?
	{
		if [[ -n "${content}" ]]; then
			printf '%s\n' "${content}"
		fi
		if [[ -n "${url}" ]]; then
			printf '%s\n' 'proxy_override_env yes' "proxy_http ${proxy}" "proxy_https ${proxy}" "proxy_rsync ${proxy}"
		fi
	} | sudo tee "${config}" >/dev/null
}

function update_ports() {
	sudo port -v selfupdate || return $?
	sudo port upgrade outdated
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
}
