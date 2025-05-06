#!/usr/bin/env bash

fatal () { # error
	echo -e "${RED}Error: ${1}${C0}" >&2
	exit 1
}

main () {
	report "*** ${APP} Updater"
	echo "This will update the latest (possibly UNTESTED and RISKY) version in current directory."
	read -p "Continue? (Y=Yes, N=No) " -n 1 -r key
	echo
	case "${key}" in
		Y|y) updateLatestMain ;;
		N|n) echo "User interrupted." ;;
		*) echo "Invalid response." ;;
	esac
}

report () { # msg
	echo -e "${GREEN}${1}${C0}"
}

updateLatestMain () {
	local pkg pkgName srcDir tmpDir url
	pkgName="${BRANCH}.zip"
	tmpDir=$(mktemp -d -t "${APP}-XXXXX")
	[ -z "${tmpDir}" ] && fatal "Failed to create temporary directory!"
	report "Created temporary directory ${tmpDir}."
 	echo "Downloading..."
	pkg="${tmpDir}/${pkgName}"
	srcDir="${tmpDir}/${APP}-${BRANCH}"
	url="${ARCHIVE}/${pkgName}"
	wget "${url}" -P "${tmpDir}" \
		&& unzip "${pkg}" -d "${tmpDir}" \
        && rm "${pkg}" \
		&& cp -r "${srcDir}"/* .
    if [ $? -eq 0 ]; then
		report "Update succeeded!"
		rm -r "${tmpDir}" && report "Temporary directories removed."
	else
		fatal "Update failed!"
    fi
}

readonly APP="tauplayer"
readonly ARCHIVE="https://github.com/jarvenja/${APP}/archive"
readonly BRANCH="main"
readonly C0="\e[0m"
readonly GREEN="\e[0;32m"
readonly RED="\e[0;31m"
main
