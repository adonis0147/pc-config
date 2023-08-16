#!/usr/bin/env bash

set -e

readonly DEVEL_ENV_PATH="${HOME}/.local/share/pc-devel-env"

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

function install_zinit() {
	if [[ ! -d "${HOME}/.local/share/zinit/zinit.git" ]]; then
		yes | bash -c "$(curl --fail --show-error --silent --location \
			https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
	fi
}

function setup_zsh() {
	local content="source \"${DEVEL_ENV_PATH}/zshrc\""

	if [[ ! -f "${HOME}/.zshrc" ]]; then
		log_error "${HOME}/.zshrc doesn't exist!"
	fi

	if ! grep "${content}" "${HOME}/.zshrc" &>/dev/null; then
		echo -e "\n${content}" >>"${HOME}/.zshrc"
	fi

	ln -snf "${DEVEL_ENV_PATH}/config/p10k.zsh" "${HOME}/.p10k.zsh"
}

function install_for_macos() {
	install_prerequisites

	if [[ ! -d "${DEVEL_ENV_PATH}" ]]; then
		git clone https://github.com/adonis0147/pc-devel-env "${DEVEL_ENV_PATH}"
	fi

	install_zinit
	setup_zsh

	ln -snf "${DEVEL_ENV_PATH}/macOS/profile.zsh" "${HOME}/.zprofile"

	if [[ ! -f "${DEVEL_ENV_PATH}/macOS/env.zsh" ]]; then
		local HOMEBREW_PREFIX
		if [[ "$(uname -m)" == 'arm64' ]]; then
			HOMEBREW_PREFIX='/opt/homebrew'
		else
			HOMEBREW_PREFIX='/usr/local'
		fi
		cat >"${DEVEL_ENV_PATH}/macOS/env.zsh" <<EOF
export HOMEBREW_PREFIX="${HOMEBREW_PREFIX}"
EOF
	fi
}

function install() {
	if [[ "$(uname -s)" == 'Darwin' ]]; then
		install_for_macos
	fi
}

install
