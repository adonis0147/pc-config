#!/usr/bin/env bash

set -e

readonly PC_CONFIG_PATH="${HOME}/.config/pc-config"

function log() {
	local level="${1}"
	local message="${2}"
	local date
	date="$(date +'%Y-%m-%d %H:%M:%S')"
	if [[ "${level}" == 'INFO' ]]; then
		level="[\033[32;1m ${level}  \033[0m]"
	elif [[ "${level}" == 'WARNING' ]]; then
		level="[\033[33;1m${level}\033[0m]"
	elif [[ "${level}" == 'ERROR' ]]; then
		level="[\033[31;1m ${level} \033[0m]"
	fi
	echo -e "${level} ${date} - ${message}"
}

function log_info() {
	local message="${1}"
	log 'INFO' "${message}"
}

function log_warning() {
	local message="${1}"
	log 'WARNING' "${message}"
}

function log_error() {
	local message="${1}"
	log 'ERROR' "${message}"
	exit 1
}

function install_prerequisites() {
	if ! command -v brew &>/dev/null; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
}

function install_zsh() {
	if ! command -v zsh &>/dev/null; then
		local OS_DISTRIBUTOR
		OS_DISTRIBUTOR="$(lsb_release -a | sed -n 's/Distributor ID:[[:space:]]*\(.*\)/\1/p')"

		if [[ "${OS_DISTRIBUTOR}" == 'Ubuntu' ]]; then
			sudo apt update
			sudo DEBIAN_FRONTEND=noninteractive apt install --yes zsh
		fi
	fi
}

function install_zinit() {
	if [[ ! -d "${HOME}/.local/share/zinit/zinit.git" ]]; then
		yes | bash -c "$(curl --fail --show-error --silent --location \
			https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
	fi
}

function setup_zsh() {
	local content="source \"${PC_CONFIG_PATH}/zshrc\""

	if [[ ! -f "${HOME}/.zshrc" ]]; then
		log_error "${HOME}/.zshrc doesn't exist!"
	fi

	if ! grep "${content}" "${HOME}/.zshrc" &>/dev/null; then
		echo -e "\n${content}" >>"${HOME}/.zshrc"
	fi

	ln -snf "${PC_CONFIG_PATH}/config/p10k.zsh" "${HOME}/.p10k.zsh"
}

function install_for_macos() {
	install_prerequisites

	if [[ ! -d "${PC_CONFIG_PATH}" ]]; then
		git clone https://github.com/adonis0147/pc-config "${PC_CONFIG_PATH}"
	fi

	install_zinit
	setup_zsh

	ln -snf "${PC_CONFIG_PATH}/macOS/profile.zsh" "${HOME}/.zprofile"

	if [[ ! -f "${PC_CONFIG_PATH}/macOS/env.zsh" ]]; then
		local HOMEBREW_PREFIX
		if [[ "$(uname -m)" == 'arm64' ]]; then
			HOMEBREW_PREFIX='/opt/homebrew'
		else
			HOMEBREW_PREFIX='/usr/local'
		fi
		cat >"${PC_CONFIG_PATH}/macOS/env.zsh" <<EOF
export HOMEBREW_PREFIX='${HOMEBREW_PREFIX}'
EOF
	fi
}

function install_for_linux() {
	if [[ ! -d "${PC_CONFIG_PATH}" ]]; then
		git clone https://github.com/adonis0147/pc-config "${PC_CONFIG_PATH}"
	fi

	install_zsh
	install_zinit
	setup_zsh

	ln -snf "${PC_CONFIG_PATH}/Linux/profile.zsh" "${HOME}/.zprofile"

	if [[ ! -f "${PC_CONFIG_PATH}/Linux/env.zsh" ]]; then
		local OS_DISTRIBUTOR
		OS_DISTRIBUTOR="$(lsb_release -a | sed -n 's/Distributor ID:[[:space:]]*\(.*\)/\1/p')"
		cat >"${PC_CONFIG_PATH}/Linux/env.zsh" <<EOF
export OS_DISTRIBUTOR='${OS_DISTRIBUTOR}'
EOF
	fi
}

function install() {
	local kernel
	kernel="$(uname -s)"

	if [[ "${kernel}" == 'Darwin' ]]; then
		install_for_macos
	elif [[ "${kernel}" == 'Linux' ]]; then
		install_for_linux
	fi

	zsh -i -c 'set -e; source "${HOME}/.zprofile"'
}

install
