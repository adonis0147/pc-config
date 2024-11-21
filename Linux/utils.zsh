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

# Ubuntu: sudo apt install squid-openssl
function setup_squid() {
	local https_proxy_server="${1}"
	local port="${2}"
	local user="${3}"
	local password="${4}"
	local config_template="${PC_CONFIG_PATH}/config/squid.conf"

	if [[ ! -f /etc/squid/squid.conf.default ]]; then
		sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.default
	fi

	sed "{
		s/<https_proxy_server>/${https_proxy_server}/
		s/<port>/${port}/
		s/<user>/${user}/
		s/<password>/${password}/
	}" "${config_template}" >/tmp/squid.conf
	sudo mv /tmp/squid.conf /etc/squid/squid.conf
}
