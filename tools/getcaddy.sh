#!/usr/bin/env bash
#
#                  Caddy Installer Script
#
#       ⚠️ THIS SCRIPT ONLY SUPPORTS v1, WHICH IS OBSOLETE ⚠️
#
#   Homepage: https://caddyserver.com
#   Issues:   https://github.com/caddyserver/getcaddy.com/issues
#   Requires: bash, mv, rm, tr, type, curl/wget, base64, sudo (if not root)
#             tar (or unzip on OSX and Windows), gpg (optional verification)
#
# This script safely installs Caddy into your PATH (which may require
# password authorization). Assuming non-commercial use, here is how
# to use it:
#
#	$ curl https://getcaddy.com | bash -s personal
#	 or
#	$ wget -qO- https://getcaddy.com | bash -s personal
#
# The syntax is:
#
#	bash -s [personal|commercial] [plugin1,plugin2,...] [accessCode1,accessCode2...]
#
# So if you want to get Caddy with extra plugins, the second
# argument is a comma-separated list of plugin names, like this:
#
#	$ curl https://getcaddy.com | bash -s personal http.git,dns
#
# If you are downloading Caddy with unlisted plugins and need to
# provide access codes: list them, separated by commas, in the third
# argument, like this:
#
#	$ curl https://getcaddy.com | bash -s personal unlisted accessCode
#
# If you purchased a commercial subscription, you must set your
# account ID and API key in environment variables:
#
#	$ export CADDY_ACCOUNT_ID=...
#	$ export CADDY_API_KEY=...
#
# Then you can request a download from your subscription:
#
#	$ curl https://getcaddy.com | bash -s commercial
#
# And the same argument syntax applies.
#
# To enable telemetry, export CADDY_TELEMETRY=on.
#
# In automated environments, you may want to run as root.
# If using curl, we recommend using the -fsSL flags.
#
# This should work on Mac, Linux, and BSD systems, and
# hopefully Windows with Cygwin. Please open an issue if
# you notice any bugs.
#

[[ $- = *i* ]] && echo "Don't source this script!" && return 10

install_caddy()
{
	echo "⚠️ This installer only supports v1, which is obsoleted now that Caddy 2 is released. This script may change or go away soon. Please upgrade: https://caddyserver.com/docs/v2-upgrade"

	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; exit 1' ERR
	caddy_license="$1"
	caddy_plugins="$2"
	caddy_access_codes="$3"
	install_path="/usr/local/bin"
	caddy_os="unsupported"
	caddy_arch="unknown"
	caddy_arm=""

	# Valid license declaration is required
	if [[ "$caddy_license" != "personal" && "$caddy_license" != "commercial" ]]; then
		echo "You must specify a personal or commercial use; see getcaddy.com for instructions."
		return 9
	fi

	# Termux on Android has $PREFIX set which already ends with /usr
	if [[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]]; then
		install_path="$PREFIX/bin"
	fi

	# Fall back to /usr/bin if necessary
	if [[ ! -d $install_path ]]; then
		install_path="/usr/bin"
	fi

	# Not every platform has or needs sudo (https://termux.com/linux.html)
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	#########################
	# Which OS and version? #
	#########################

	caddy_bin="caddy"
	caddy_dl_ext=".tar.gz"

	# NOTE: `uname -m` is more accurate and universal than `arch`
	# See https://en.wikipedia.org/wiki/Uname
	unamem="$(uname -m)"
	if [[ $unamem == *aarch64* ]]; then
		caddy_arch="arm64"
	elif [[ $unamem == *64* ]]; then
		caddy_arch="amd64"
	elif [[ $unamem == *86* ]]; then
		caddy_arch="386"
	elif [[ $unamem == *armv5* ]]; then
		caddy_arch="arm"
		caddy_arm="5"
	elif [[ $unamem == *armv6l* ]]; then
		caddy_arch="arm"
		caddy_arm="6"
	elif [[ $unamem == *armv7l* ]]; then
		caddy_arch="arm"
		caddy_arm="7"
	else
		echo "Aborted, unsupported or unknown architecture: $unamem"
		return 2
	fi

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ $unameu == *DARWIN* ]]; then
		caddy_os="darwin"
		caddy_dl_ext=".zip"
		vers=$(sw_vers)
		version=${vers##*ProductVersion:}
		IFS='.' read OSX_MAJOR OSX_MINOR _ <<<"$version"

		# Major
		if ((OSX_MAJOR < 10)); then
			echo "Aborted, unsupported OS X version (9-)"
			return 3
		fi
		if ((OSX_MAJOR > 10)); then
			echo "Aborted, unsupported OS X version (11+)"
			return 4
		fi

		# Minor
		if ((OSX_MINOR < 5)); then
			echo "Aborted, unsupported OS X version (10.5-)"
			return 5
		fi
	elif [[ $unameu == *LINUX* ]]; then
		caddy_os="linux"
	elif [[ $unameu == *FREEBSD* ]]; then
		caddy_os="freebsd"
	elif [[ $unameu == *OPENBSD* ]]; then
		caddy_os="openbsd"
	elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
		# Should catch cygwin
		sudo_cmd=""
		caddy_os="windows"
		caddy_dl_ext=".zip"
		caddy_bin=$caddy_bin.exe
	else
		echo "Aborted, unsupported or unknown os: $uname"
		return 6
	fi

	########################
	# Download and extract #
	########################

	echo "Downloading Caddy for ${caddy_os}/${caddy_arch}${caddy_arm} (${caddy_license} license)..."
	caddy_file="caddy_${caddy_os}_${caddy_arch}${caddy_arm}_custom${caddy_dl_ext}"
	qs="license=${caddy_license}&plugins=${caddy_plugins}&access_codes=${caddy_access_codes}&telemetry=${CADDY_TELEMETRY}"
	caddy_url="https://github.com/caddyserver/caddy/releases/download/v1.0.4/caddy_v1.0.4_linux_${caddy_arch}.tar.gz"
	caddy_asc="https://caddyserver.com/download/${caddy_os}/${caddy_arch}${caddy_arm}/signature?${qs}"

	type -p gpg >/dev/null 2>&1 && gpg=1 || gpg=0

	# Use $PREFIX for compatibility with Termux on Android
	dl="$PREFIX/tmp/$caddy_file"
	rm -rf -- "$dl"


	curl -fsSL "$caddy_url" -u "$CADDY_ACCOUNT_ID:$CADDY_API_KEY" -o "$dl"
	
	
	
	echo "Extracting..."
	case "$caddy_file" in
		*.zip)    unzip -o "$dl" "$caddy_bin" -d "$PREFIX/tmp/" ;;
		*.tar.gz) tar -xzf "$dl" -C "$PREFIX/tmp/" "$caddy_bin" ;;
	esac
	chmod +x "$PREFIX/tmp/$caddy_bin"

	# Back up existing caddy, if any found in path
	if caddy_path="$(type -p "$caddy_bin")"; then
		caddy_backup="${caddy_path}_old"
		echo "Backing up $caddy_path to $caddy_backup"
		echo "(Password may be required.)"
		$sudo_cmd mv "$caddy_path" "$caddy_backup"
	fi

	echo "Putting caddy in $install_path (may require password)"
	$sudo_cmd mv "$PREFIX/tmp/$caddy_bin" "$install_path/$caddy_bin"
	if setcap_cmd=$(PATH+=$PATH:/sbin type -p setcap); then
		$sudo_cmd $setcap_cmd cap_net_bind_service=+ep "$install_path/$caddy_bin"
	fi
	$sudo_cmd rm -- "$dl"

	# check installation
	$caddy_bin -version

	echo "Successfully installed"
	trap ERR
	return 0
}

install_caddy "$@"
