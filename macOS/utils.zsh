function install_neovim() {
	local url='https://api.github.com/repos/neovim/neovim/releases/latest'
	local latest
	local current

	latest="$(curl -s "${url}" |
		python -c "import json; import sys; print(json.load(sys.stdin)['tag_name'])")"

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

function install_rust() {
	if ! bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y --no-modify-path; then
		return
	fi

	local content='[[ -f "${HOME}/.cargo/env" ]] && source "${HOME}/.cargo/env" '
	if ! grep "${content}" "${HOME}/.zshenv" &>/dev/null; then
		echo "\n${content}" >>"${HOME}/.zshenv"
		eval "${content}"
	fi
}
