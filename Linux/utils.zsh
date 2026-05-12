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

function setup_mihomo() {
	local url="${1}"
	local ui_host="${2}"
	local config="${PC_CONFIG_PATH}/config/mihomo.yaml"

	if [[ -z "${ui_host}" ]]; then
		ui_host='127.0.0.1'
	fi

	mkdir -p "${HOME}/.config/mihomo"

	sed "{
		s|\(external-controller: \).*|\1\"${ui_host}:9090\"|
		s|\(url: \)\"\"|\1\"${url}\"|
	}" "${config}" >"${HOME}/.config/mihomo/config.yaml"

	systemctl --user enable "${PC_CONFIG_PATH}/config/systemd/mihomo.service"

	if [[ "$(loginctl show-user "${USER}" | sed -n 's/Linger=\(.*\)/\1/p')" == 'no' ]]; then
		sudo loginctl enable-linger "${USER}"
	fi
}

function setup_docker() {
	local arch
	arch="$(uname -m)"
	local base_url="https://download.docker.com/linux/static/stable/${arch}"
	local version

	version="$(curl -sL "${base_url}" | grep -oP 'docker-\K[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?(?=\.tgz)' | sort -V | tail -n 1)"

	if [[ -z "${version}" ]]; then
		echo -e "\033[31;1mFailed to fetch Docker version\033[0m"
		return 1
	fi

	local download_url="${base_url}/docker-${version}.tgz"
	local install_path="/opt/docker"
	local tmp_path="/tmp/docker"

	rm -rf "${tmp_path}"
	mkdir -p "${tmp_path}"
	if ! curl -L "${download_url}" -o - | tar -xz -C "${tmp_path}" --strip-components=1 ; then
		echo -e "\033[31;1mFailed to download or extract Docker\033[0m"
		return 1
	fi

	sudo rm -rf "${install_path}"
	sudo mv "${tmp_path}" "${install_path}"

	sudo groupadd -f docker
	sudo usermod -aG docker "${USER}"

	sudo systemctl enable "${PC_CONFIG_PATH}/config/systemd/dockerd.service"

	newgrp docker
}

function update_all() {
	update_zinit
	update_uv
	update_node
	update_rust
	update_sdk
}
