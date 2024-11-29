source "${PC_CONFIG_PATH}/common/utils.zsh"

# Ubuntu: sudo apt install squid-openssl
function setup_squid() {
	local https_proxy_server="${1}"
	local port="${2}"
	local user="${3}"
	local password="${4}"
	local config="${PC_CONFIG_PATH}/config/squid.conf"

	if [[ ! -f /etc/squid/squid.conf.default ]]; then
		sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.default
	fi

	sed "/^never_direct/i \\
cache_peer ${https_proxy_server} parent ${port} 0 background-ping no-digest weighted-round-robin login=${user}:${password} ssl" \
	"${config}" >/tmp/squid.conf
	sudo mv /tmp/squid.conf /etc/squid/squid.conf
}

function update_all() {
	update_zinit
	update_rye
	update_node
	update_rust
	update_sdk
}
