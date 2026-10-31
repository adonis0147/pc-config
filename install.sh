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

function install_macports() (
	local os url tmp
	os=$(sw_vers -productVersion |
		awk -F. '{print ($1 == 10 ? $1 "." $2 : $1)}')

	url=$(curl -fsSL https://guide.macports.org/ |
		grep -oE "https://github.com/macports/macports-base/releases/download/[^\" ]*/MacPorts-[^-]+-${os}-[^\" ]+\.pkg") ||
		log_error "Could not find a MacPorts package URL for macOS ${os}"

	log_info "MacPorts package: ${url}"

	tmp="$(mktemp -d)"
	trap 'rm -rf "${tmp}"' EXIT
	curl -fL "${url}" -o "${tmp}/MacPorts.pkg"
	sudo installer -pkg "${tmp}/MacPorts.pkg" -target /
)

function install_prerequisites() {
	local manager="${1}"

	if [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	if [[ "${manager}" == 'macports' ]]; then
		if [[ ! -x /opt/local/bin/port ]]; then
			install_macports
		fi
	fi
}

function install_package() {
	local package="${1}"
	if ! command -v "${package}" &>/dev/null; then
		local OS_DISTRIBUTOR
		OS_DISTRIBUTOR="$(lsb_release -a 2>/dev/null | sed -n 's/Distributor ID:[[:space:]]*\(.*\)/\1/p')"

		if [[ "${OS_DISTRIBUTOR}" == 'Ubuntu' ]]; then
			sudo apt update
			sudo DEBIAN_FRONTEND=noninteractive apt install --yes "${package}"
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
	local arg options
	local -a args=()

	# Apple's getopt only supports short options.
	for arg in "${@}"; do
		case "${arg}" in
		--macports) args+=("-m") ;;
		*) log_error "Unknown argument: ${arg}" ;;
		esac
	done

	options=$(/usr/bin/getopt m "${args[@]}") || return 1
	eval set -- "${options}"

	local manager="homebrew"
	while [[ "${1}" != "--" ]]; do
		case "${1}" in
		-m) manager="macports" ;;
		esac
		shift
	done

	install_prerequisites "${manager}"

	if [[ ! -d "${PC_CONFIG_PATH}" ]]; then
		git clone https://github.com/adonis0147/pc-config "${PC_CONFIG_PATH}"
	fi

	install_zinit
	setup_zsh

	ln -snf "${PC_CONFIG_PATH}/macOS/profile.zsh" "${HOME}/.zprofile"

	local content="export PACKAGE_MANAGER='${manager}'"
	if ! grep "${content}" "${PC_CONFIG_PATH}/macOS/env.zsh" &>/dev/null; then
		echo "${content}" >>"${PC_CONFIG_PATH}/macOS/env.zsh"
	fi

	local HOMEBREW_PREFIX
	if [[ "$(uname -m)" == 'arm64' ]]; then
		HOMEBREW_PREFIX='/opt/homebrew'
	else
		HOMEBREW_PREFIX='/usr/local'
	fi
	content="export HOMEBREW_PREFIX='${HOMEBREW_PREFIX}'"
	if ! grep "${content}" "${PC_CONFIG_PATH}/macOS/env.zsh" &>/dev/null; then
		echo "${content}" >>"${PC_CONFIG_PATH}/macOS/env.zsh"
	fi
}

function install_for_linux() {
	if [[ ! -d "${PC_CONFIG_PATH}" ]]; then
		git clone https://github.com/adonis0147/pc-config "${PC_CONFIG_PATH}"
	fi

	install_package zsh
	install_package unzip
	install_package jq
	install_zinit
	setup_zsh

	ln -snf "${PC_CONFIG_PATH}/Linux/profile.zsh" "${HOME}/.zprofile"

	local OS_DISTRIBUTOR
	OS_DISTRIBUTOR="$(lsb_release -a 2>/dev/null | sed -n 's/Distributor ID:[[:space:]]*\(.*\)/\1/p')"
	local content="export OS_DISTRIBUTOR='${OS_DISTRIBUTOR}'"
	if ! grep "${content}" "${PC_CONFIG_PATH}/Linux/env.zsh" &>/dev/null; then
		echo "${content}" >>"${PC_CONFIG_PATH}/Linux/env.zsh"
	fi

	if [[ "${OS_DISTRIBUTOR}" == 'Ubuntu' ]]; then
		# https://github.com/zdharma-continuum/zinit?tab=readme-ov-file#disabling-system-wide-compinit-call-ubuntu
		content='skip_global_compinit=1'
		if ! grep "${content}" "${HOME}/.zshenv" &>/dev/null; then
			echo -e "\n${content}" >>"${HOME}/.zshenv"
		fi
	fi

	local file="${PC_CONFIG_PATH}/Linux/${OS_DISTRIBUTOR}.zsh"
	if [[ -f "${file}" ]]; then
		content="source '${file}'"
		if ! grep "${content}" "${PC_CONFIG_PATH}/Linux/env.zsh" &>/dev/null; then
			echo -e "\n${content}" >>"${PC_CONFIG_PATH}/Linux/env.zsh"
		fi
	fi
}

function install() {
	local kernel
	kernel="$(uname -s)"

	if [[ "${kernel}" == 'Darwin' ]]; then
		install_for_macos "${@}"
	elif [[ "${kernel}" == 'Linux' ]]; then
		install_for_linux "${@}"
	fi

	zsh -i -c 'set -e; source "${HOME}/.zprofile"'
}

install "${@}"
