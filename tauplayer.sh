#!/usr/bin/env bash
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#               Terminal Audio (tau) Player
#                   Copyright (c) 2025
#            Janne Järvenpää <jarvenja@gmail.com>
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

# About principles:
# 1. bash scripting has somewhat different rules (bashism) than true programming languages

addValidStream () { # validName validUrl
	local err file
	[ $# -ne 2 ] && invalidArg "${1} MUST be run alone!"
	file=$(getCollectionPath)
	$(echo "${1},${2}" >> "${file}") && sort -o "${file}"{,}
}

archive () { # collection
	local bak f
	f=$(getCollectionPath "${1}")
	bak=$(getBackupPath "${1}")
	if mv -v "${f}" "${bak}" >/dev/null; then
		report "${1} was archived"
	else
		report "Cannot remove ${1}!"
	fi
}

batch () { # arg argc
	[ "${2}" -ne 1 ] && fatal "${1} MUST be run alone!"
	case "${1}" in
		--colors) showColors ;;
		--colors=*) changeColors "${1:9}" ;;
		--help) usage ;;
		--license) viewLicense ;;
		--settings) loadSettings "${SETTINGS}" ; printSettings ;;
		--term) echo "Your terminal type is '${TERM}' which may affect to see correct colors or characters." ;;
		*) invalidArg "${1}" ;;
	esac
	popd > /dev/null
	exit 0
}

blink () { # text
	[ $# -eq 1 ] || wrongArgCount "$@"
	[ "${BLINK}" == on ] && echo "${BLINKI}${1}${BLINKO}" || echo "${1}"
}

catch () {
	local code cmd lineno
	code=$?
	cmd="${BASH_COMMAND}"
	lineno="${BASH_LINENO}"
	printf "${WARN}The line %d: %s\nreturned %d\n${NORMAL}" "${lineno}" "${cmd}" "${code}"
	# FixMe: Printing multiple lines...
}

changeColors () { # newColor
	if [[ ${COLORINGS[@]} =~ ${1} ]]; then
		loadSettings "${SETTINGS}"
		COLORING="${1}"
		saveSettings
	else 
		echo "Unknown color ${1}."
	fi
}

check () { # checkvalue
	[[ "${1}" =~ ^(off|on)$ ]]
}

clearMsg () {
	MSG=""
}

collectionMenu () { # action
	local c line
	local -i dlg
	local -a entries
	while read -r line; do
		c="${line##*/}"
		c="${c%.cvs}"
		[ "${c}" == "${COLLECTION}" ] || entries+=("${c}" "")
	done < <(find "${COLLECTION_DIR}" -name "*.cvs" | sort)
    [ "${#entries[@]}" -eq 0 ] && fatal "No collections found in ${COLLECTION_DIR}."
	clearMsg
	tput civis || terror
	tryOff
	c=$(dialog \
		--stdout \
 		--backtitle "$(getTitle)" \
 		--title " ${1} Collection " \
 		--clear \
		--cancel-label "Cancel" \
		--ok-label "Select" \
		--menu "\n${MSG}" 0 0 16 \
		"${entries[@]}"
	)
	dlg=$?
	tryOn
	tput cnorm || terror
	if [ "${dlg}" -eq "${DLG_OK}" ]; then
		case "${1}" in
			Change) COLLECTION="${c}" ;;
			Remove) archive "${c}" ;;
			*) invalidArg "${1}" ;;
		esac
	fi
}

createCollection () { # validName
	local f
	f=$(getCollectionPath "${1}")
	if [ -f "${f}" ]; then
		fatal "File ${f} already exists!"
	else
		touch "${f}"
		[ $? -ne 0 ] && fatal "Couldn\'t create collection ${1}!"
	fi
}

die () {
	popd > /dev/null
	tput cnorm || terror
	tput init || terror
	clear
	saveSettings
	trap - ERR
	trap - EXIT
	# remove temp
	echo "Until we hear again..."
}

ensureBash () {
	local t
	t=$(getShellType)
	[ "${t}" == "bash" ] || fatal "Must be run by bash instead of ${t}"
}

ensureCommands () { # cmds...
	local cmds
	cmds=$(getMissingCommands "$@")
	if [ -n "${cmds}" ]; then
		intro
		echo -ne "\n${APPLICATION} requires the following commands to operate: ${BAD}${cmds}${NORMAL}\n"
		echo "Please install missing dependencies and try again."
		echo "=> sudo apt update && sudo apt-get install ${cmds}"
		fatal "Missing dependencies"
	fi
}

ensureConfig () {
	[ -f "${DIALOGRC}" ] || fatal ".dialogrc file not found in directory!"
	[ -d "${COLLECTION_DIR}" ] || mkdir "${COLLECTION_DIR}"
	if [ -f "${SETTINGS}" ]; then
		loadSettings "${SETTINGS}"
	else #=> ensure tauplayer.cvs and ./collections/favorites.cvs
		touch $(getCollectionPath "${COLLECTION1}")
		COLLECTION="${COLLECTION1}"
		PLAYLIST_DIR="${HOME}"
		saveSettings
	fi
}

ensureDir () { # dir
	[ -d "${1}" ] || fatal "Invalid directory ${1}!"
}

ensureFile () { # file
	[ -f "${1}" ] || fatal "File ${1} not found!"
}

ensureInternet () {
	local code
	code=$(getHttpResponseStatus "${GG}")
	[ "${code}" -eq 200 ] || fatal "No connection available to reach ${GG}!"
}

error () { # msg
	echo -ne " ${WARN}Error: ${1}${NORMAL}" >&2
}

fail () { # reason
	echo -ne " ${WARN}[${1}]${NORMAL}\n"
	# inputKey
}

fatal () { # msg
	echo -e "${BAD}Fatal Error: ${1}${NORMAL}" >&2
	exit 1
}

handleDlgReturn () { # dlgReturnValue
	case "${1}" in
 		"${DLG_CANCEL}"|"${DLG_ESC}") ;; # normally ignored
 		 *) warn "Unhandled dialog return code ${1} in ${FUNCNAME[1]}" ;;
	esac
}

getBackupPath () { # collectionName
	local initial path
	initial="${COLLECTION_DIR}/${1}"
	path="${initial}.bak"
	for ((i=1; -f "${path}" ;i++)); do
		path="${initial}-${i}.bak"
	done
	echo "${path}"
}

getCollectionPath () { # [collectionName]
	echo "${COLLECTION_DIR}/${1:-${COLLECTION}}.cvs"
}

getDistributor () {
	local did
	did=$(lsb_release -i)
	echo "${did:16}"
}

# Based on https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#server_error_responses
getHttpResponseName () { # code
	[ $# -eq 1 ] || wrongArgCount "$@"
  	case "${1}" in
		000) echo "No response" ;;
    	100) echo "Continue" ;;
     	101) echo "Switching Protocols" ;;
     	102) echo "Processing" ;;
     	103) echo "Early Hints" ;;
 		200) echo "OK" ;;
     	201) echo "Created" ;;
		202) echo "Accepted" ;;
 		203) echo "Non-Authoritative Information" ;;
 		204) echo "No Content" ;;
 		205) echo "Reset Content" ;;
 		206) echo "Partial Content" ;;
 		300) echo "Multiple Choices" ;;
 		301) echo "Moved Permanently" ;;
 		302) echo "Found" ;;
 		303) echo "See Other" ;;
		304) echo "Not Modified" ;;
 		305) echo "Use Proxy" ;;
 		306) echo "Status not defined" ;;
 		307) echo "Temporary Redirect" ;;
 		308) echo "Permanent Redirect" ;;
		400) echo "Bad Request" ;;
		401) echo "Unauthorized" ;;
		402) echo "Payment Required" ;;
		403) echo "Forbidden" ;;
		404) echo "Not Found" ;;
		405) echo "Method Not Allowed" ;;
		406) echo "Not Acceptable" ;;
		407) echo "Proxy Authentication Required" ;;
		408) echo "Request Timeout" ;;
 		409) echo "Conflict" ;;
	 	410) echo "Gone" ;;
		411) echo "Length Required" ;;
 		412) echo "Precondition Failed" ;;
 		413) echo "Request Entity Too Large" ;;
 		414) echo "Request-URI Too Long" ;;
 		415) echo "Unsupported Media Type" ;;
 		416) echo "Requested Range Not Satisfiable" ;;
 		417) echo "Expectation Failed" ;;
 		418) echo "I'm a teapot" ;;
 		421) echo "Misdirected Request" ;;
 		422) echo "Unprocessable content" ;;
 		423) echo "Locked" ;;
 		424) echo "Failed Dependency" ;;
 		425) echo "Too Early" ;;
 		426) echo "Upgrade Required" ;;
 		428) echo "Precondition Required" ;;
 		429) echo "Too Many Requests" ;;
 		431) echo "Request Header Fields Too Large" ;;
 		451) echo "Unavailable For Legal Reasons" ;;
 		500) echo "Internal Server Error" ;;
 		501) echo "Not Implemented" ;;
 		502) echo "Bad Gateway" ;;
 		503) echo "Service Unavailable" ;;
 		504) echo "Gateway Timeout" ;;
 		505) echo "HTTP Version Not Supported" ;;
		506) echo "Variant Also Negotiates" ;;
		507) echo "Insufficient Storage" ;;
		508) echo "Loop Detected" ;;
		510) echo "Not Extended" ;;
		511) echo "Network Authentication Required" ;;
     	*) echo "Undefined" ;; # Non-standard or customized
	esac
}

# FixMe! --head !!
getHttpResponseStatus () { # url
	local code
	code=$(curl -o /dev/null --silent --head --write-out "%{http_code}\n" "${1}")
	echo "${code}"
}

getKeyValue () { # key
	local f value
	f=$(getCollectionPath "${COLLECTION}")
	ensureFile "${f}"
	value=$(grep "^${1}," "${f}" | cut -d"," -f2-)
	echo "${value}"
}

getMissingCommands () { # cmds...
	local missing
	missing=""
	for cmd in "$@"; do
		command -v "${cmd}" &>/dev/null
		[ $? -eq 0 ] || missing+="${cmd//_/-} "
	done
	echo "${missing}"
}

getShellType () {
	local x
	x=$(ps -p $$)
	[ $? -eq 0 ] && echo "${x##* }"
}

getTitle () {
	echo -ne "${PRODUCT} -=- [${COLLECTION}]"
}

hasKey () { # key
	local f match
	f=$(getCollectionPath "${COLLECTION}")
	ensureFile "${f}"
	match=$(grep "^${1}," "${f}")
	[ -n "${match}" ]
}

haspace () { # str
	[[ ${1} =~ [[:space:]]+ ]]
}

hasText () { # str
	[[ ${1} =~ [[:alnum:]]+ ]]
}

horizon () { # [width]
	local -i n
	n="${1:-$(tput cols)}"
	while ((n-- > 0)); do
		printf "${DASH}"
	done
}

informWaiting () { # slowOperation
	echo -ne "${1}..."
}

inputKey () {
	echo; echo
	print ">> Press a key to continue..."
	read -rsn 1
}

inputNewCollection () {
	local file key name
	key="?"; name=""
	resetScreen "New Collection"
	print "Type an unique name for collection.\n"
	print "- Only letters, numbers and dash (-) are allowed.\n"
	print "- Use left arrow [<-] to remove last letter.\n"
	print "- Leave it empty to cancel\n\n"
	print "> Collection Name: "
	IFS=
	while [ "${key}" != '' ]; do
		read -rsn 1 key
		if [ "${key}" == ${ESC} ]; then
			read -rsn 2 key
			if [[ -n "${name}" && "${key}" == '[D' ]]; then
				echo -ne "\b \b"
				name="${name::-1}"
			fi
		else
			if [[ "${key}" =~ ${FILENAME_CHAR} ]]; then
				name+="${key}"
				echo -ne "${key}"
			fi
		fi
	done
	unset IFS
	[ -z "${name}" ] && return
	file=$(getCollectionPath "${name}")
	if [ -f "${file}" ]; then
		fail "Already exists"
		inputKey
	else
		createCollection "${name}"
		COLLECTION="${name}"
		report "New collection changed"
	fi
}

inputNewStream () {
	local err name url
	resetScreen "Add New Stream"
	print "Type an unique name and URL or leave blank to cancel\n\n"
	print "x Collection: ${COLLECTION}\n"
	name=$(inputValidStreamName)
	[ -z "${name}" ] && return
	url=$(inputValidStreamUrl)
	[ -z "${url}" ] && return
	$(addValidStream "${name}" "${url}")
	if [ $? -eq 0 ]; then
		inform "Stream added.\n"
		log "Added '${name},${url}' into ${COLLECTION}"
	fi
}

inputValidStreamName () { # [old]
	local url
	while :; do
		read -r -p " > Name: " -i "${1:-}" -e name
		[ -z "${name}" ] && break # cancel by user
		# TODO add more invalid characters
		if [[ "${name}" == *,* ]]; then fail "Invalid characters"
		else
			if [[ $(hasKey "${name}") ]]; then fail "Already exists"
			else
				echo "${name}"
				break
			fi
		fi
	done
}

inputValidStreamUrl () { # [old]
	read -r -p "  > URL: " -i "${1:-}" -e url
	# TODO check URL
	[ -z "{url}" ] || echo "${url}"
}

intro () {
	echo "*** ${PRODUCT}"
}

invalidArg () { # arg
	fatal "Invalid argument '${1}' in ${FUNCNAME[1]}"
}

loadSettings () { # [settingsFile]
	local collection file pld
	[ $# -eq 1 ] || wrongArgCount "$@"
	IFS=, read COLORING pld collection RECENT_NAME RECENT_URL BLINK MODULE_INFO SHUFFLE < "${1}"
	unset IFS
	[ -d "${pld}" ] && PLAYLIST_DIR="${pld}" || PLAYLIST_DIR="${HOME}"
	# ensure COLLECTION..
	COLLECTION="${COLLECTION1}"
	if [[ -n "${collection}" ]]; then
		file=$(getCollectionPath "${collection}")
		[ -f "${file}" ] && COLLECTION="${collection}"
	fi
	# set coloring dependent values..
	[ -z "${COLORING}" ] || [ "${#COLORING}" -gt "${COLORING_MAX}" ] && resetColoring
	setBars "${COLORING}" || true
	# ensure playback preferences..
	check "${BLINK}" || BLINK=off
	check "${MOD_INFO}" || MOD_INFO=off
	check "${SHUFFLE}" || SHUFFLE=off
}

log () { # msg
	[ -n "${LOG}" ] && echo "${1}" >> "${LOG}" || true
}

mainMenu () {
	local action choice
	local -a menu
	local -i dlg
	while :; do
		menu=( \
			"v" "Audio Settings..." \
			"k" "View Player Controls..." \
			"c" "Change Active Collection..." \
			"n" "Create New Collection..." \
			"r" "Remove Collection from list..." \
			"p" "Playback preferences..." \
			"l" "Play list..." \
			"s"	"Play Radio Stream..." \
			"a" "Add New Stream..." \
			"u" "Update Stream..." \
			"e" "Remove Stream..." \
			"i" "View license..."
		)
		tput civis || terror
		tryOff
		choice=$(dialog \
			--stdout \
			--backtitle "$(getTitle)" \
			--title "" \
			--clear \
			--cancel-label "Exit" \
			--ok-label "Select" \
			--menu "${MSG}" 0 44 16 \
 			"${menu[@]}"
		)
    	dlg=$?
		tryOn
		tput cnorm || terror
		clearMsg
		if [[ "${dlg}" -eq "${DLG_OK}" ]]; then
			case "${choice}" in
		    	v) alsamixer ;;
				k) printFullKeys ;;
				c) collectionMenu "Change" ;;
				n) inputNewCollection || true ;;
				r) collectionMenu "Remove" ;;
				p) playbackMenu || true ;;
				l) playList ;;
				s) streamMenu "Listen" || true ;;
				a) inputNewStream || true ;;
				u) streamMenu "Update" || true ;;
				e) streamMenu "Remove" || true ;;
				i) viewLicense || true ;;
				*) invalidArg "${choice}" ;;
			esac
		else
			handleDlgReturn "${dlg}"
			break
		fi
	done
}

now () {
	echo $(date '+%a %d-%m-%Y %T')
}

play () { # [streamName] url
	local cmd keys label line mp3floats prev sign title
	local -a playback
	playback=()
	if [ -z "${1}" ]; then # play list
		[ "${PLAYLIST_CACHE}" == true ] && playback+=(-cache "${CACHE_SIZE}" -cache-min "${CACHE_MIN}")
		[ "${SHUFFLE}" == on ] && playback+=(-shuffle)
		keys="printLocalKeys"
		label=""
		sign=$(blink "${PLAYING2}[>]")
		title="${PLAYLIST}"
		RECENT_NAME="${PLAYLIST}"
		playback+=(-playlist)
	else
		keys="printStreamKeys"
		label="${1}\n         "
		sign=$(blink "((")
		sign+=" A "
		sign+=$(blink "))")
		title="[${COLLECTION}]"
		RECENT_NAME="${1}"
	fi
	RECENT_URL="${2}"
	cmd="${PLAYER} ${PLAY_PARAMS} ${playback[*]} ${2}"
	# log "${cmd}"
	tryOff # since interaction with 3rd party modules
	$(echo -ne "${cmd}") |
	{	echo
		mp3floats=false
		prev=""
		while IFS= read -r line; do
			if [[ "${line}" == *"[mp3float"* ]]; then
				if [ "${mp3floats}" == false ]; then
					error "Bad audio quality (mp3float)!"
					mp3floats=true
				fi
			else
				case "${line}" in
					Playing*) # new screen for each...
						resetScreen "${title}"
						(${keys})
						echo ; echo -e " ${PLAYING1}${sign}  ${label} \e[0m${PLAYING2}${2} "
						;;
					'') ;;
					*"="*|*"audio codec"*|*AO:*|*AUDIO:*|*"ICY Info:"*|*libav*|*Video:*)
						[ "${MODULE_INFO}" == on ] && print "${line}"
						;;
					*)	if [ "${line}" == "${prev}" ]; then
							echo -ne "${WARN}|${NORMAL}"
						else
							echo -ne "\n ${line} "
							prev="${line}"
						fi
						;;
				esac
			fi
	  	done
	}
	tryOn # back to default
	report "Playback stopped"
}

playbackMenu () {
	local checks dlg
	tput civis || terror
	checks=$(dialog \
		--stdout \
		--backtitle "$(getTitle)" \
		--title " Playback Preferences " \
		--clear \
		--ok-label "Update" \
		--checklist "\nUse arrow keys and space bar" 0 34 6 \
		"${BLINK_ID}" "Blink playing icon" "${BLINK}" \
		"${SHUFFLE_ID}" "Shuffle playlist" "${SHUFFLE}" \
		"${MOD_INFO_ID}" "Module Info" "${MOD_INFO}" \
		--output-fd 1
	)
	dlg=$?
	tput cnorm || terror
	[ "${dlg}" -eq "${DLG_OK}" ] && updatePlaybackSettings "${checks}" || handleDlgReturn "${dlg}"
}

playList () {
	local pl
	resetScreen "Play list"
	print "I will list you all .m3u playlists under...\n"
	while :; do
		read -r -p "> Scanning directory: " -i "${PLAYLIST_DIR}" -e dir
		if [ $? -ne 0 ]; then
			log "Reading new directory name (${dir}) returned $?"
			report "Read Error"
			return
		fi
		if [ -z "${dir}" ]; then
			clearMsg
			return
		fi
		if [ -d "${dir}" ]; then
			PLAYLIST_DIR="${dir}"
			break
		fi
	done
	pl=$(playlistMenu)
	[ -n "${pl}" ] && play "" "${pl}"
}

playlistMenu () {
	local file
	local -i dlg
	local -a entries
	entries=()
	while read -r pl; do
		haspace "${pl}" || entries+=("${pl}" "")
	done < <(find "${PLAYLIST_DIR}" -name "*.m3u" -type f)
	if [[ "${#entries[@]}" -eq 0 ]]; then
		report "No playlists found"
	else # one or more playlists
		clearMsg
		# FixMe! tput civis
		tryOff
		file=$(dialog \
			--stdout \
			--clear \
			--backtitle "$(getTitle)" \
			--title " Playlists found " \
			--cancel-label "Cancel" \
			--ok-label "Play" \
			--menu "\n${MSG}" 0 0 16 \
 			"${entries[@]}"
		)
		dlg=$?
		tryOn
		# FixMe! tput cnorm
	    [ "${dlg}" -eq "${DLG_OK}" ] && echo "${file}" || handleDlgReturn "${dlg}"
	fi
}

playStream () { # name url
	local code
	[ "$#" -eq 2 ] || wrongArgCount "$@"
	resetScreen "Pre-check"
	informWaiting "Loading"
	code=$(getHttpResponseStatus "${2}")
	case "${code}" in
		200|302|400|404|405) play "${1}" "${2}" ;;
		*) reportUnavailability "${1}" "${2}" "${code}" ;;
	esac
}

# printf '%s|' "${array[@]}

print () { # line
	[ $# -eq 1 ] || wrongArgCount "$@"
	echo -ne " ${1}" # create one space margin
}

# TODO highlights
printFullKeys () {
	resetScreen "${PLAYER} Controls"
	echo -e "$(horizon 6) Track $(horizon 15)"
    printKey "        Stop" "[Esc]"
	printKey "       Pause" "P [Space]"
	printKey "   Prev/Next" "< >"
	printKey "      -/+10s" "<- ->"
	printKey "     -/+1min" "[Up] [Down]"
 	printKey "    -/+10min" "[Pg] [PgUp]"
	echo -e "$(horizon 3) Playback Speed $(horizon 9)"
	printKey "        100%" "[BkSp]"
	printKey "         50%" "{"
	printKey "      -/+10%" "[ ]"
	printKey "          x2" "  }"
	echo -e "$(horizon 5) Volume $(horizon 15)"
	printKey "        Vol-" "9 /"
	printKey "        Vol+" "0 *"
	printKey "        Mute" "M"
	printKey "     Balance" "( )"
	echo -e "$(horizon 28)"
	inputKey
}

printKey () { # function key
	echo -e " ${1}  ${BOLD}${2}${NORMAL}"
}

printLocalKeys () {
	printUpperBar "  Stop  Pause  Prev  Next -10s  +10s -1min  +1min          \n"
	printLowerBar " [Esc]  [Spc]    <    >   [<-]  [->]  [Up]  [Down]         \n"
	echo
	printUpperBar "  100%   50%  -10%  +10%   x2   Vol-  Vol+  Mute  Balance  \n"
	printLowerBar " [BkSpc]   {     [    ]     }    9 /   0 *   [M]     (  )  \n"
}

printLowerBar () { # txt
	echo -ne "${KEY_COLOR}${1}\e[0m"
}

printSettings () {
	local -a vars
	vars=(BLINK COLLECTION COLORING LOG MOD_INFO PLAYLIST_DIR RECENT_NAME RECENT_URL SHUFFLE)
	for var in "${vars[@]}"; do
		echo "${var}=${!var}"
	done
}

printStreamKeys () {
	printUpperBar "  Stop   Pause   100%   50%  -10%  +10%   x2   Vol-  Vol+  Mute  Balance  \n"
	printLowerBar "  [Esc]  [Spc]  [BkSpc]  {     [    ]     }    9 /   0 *   [M]    (  )    \n"
}

printUpperBar () { # txt
	echo -ne "${LABEL_COLOR}${1}\e[0m"
}

removeCollection () {
	local c
	c=$(collectionMenu "Remove")
	[ -n "${c}" ] && archiveFile getCollectionPath "${c}"
}

removeKey () { # key value filepath
	$(sed -i '/^$1,/s/.*/${2}/' "${3}")
}

removeSettings () {
	rm "${SETTINGS}" && echo "Settings cleared."
}

removeStream () { # name url
	local file
	file=$(getCollectionPath)
	$(sed -i "/${1}/d" "${file}")
	if [ $? -eq 0 ]; then
		report "Stream removed"
	else
		fatal "Failed ($?) to remove stream '${1}' with data '${2}'"
	fi
}

replaceKeyValue () { # key value filepath
	$(sed -i '/^$1,/s/.*/${2}/' "${3}")
	[ $? -eq 0 ] || error "Unable to update key '${1}'!"
}

report () { # msg
	[ $# -eq 1 ] || wrongArgCount "$@"
	MSG="-> ${1}"
}

reportUnavailability () { # streamName url code
	local responseName
	[ $# -eq 3 ] || wrongArgCount "$@"
	resetScreen "Stream Not Available"
	print "Pre-check failed with the following details:\n\n"
	print "Type: Stream\n"
	print "Name: ${1}\n"
	print " URL: ${2}\n\n"
	responseName=$(getHttpResponseName "${3}")
	print "HTTP ->"
	fail "${3} ${responseName}"
	inputKey
}

resetColoring () {
	local x
	x=$(getDistributor)
	case "${x}" in
		# TODO add more
		Linuxmint) x=rich ;;
		Rasbian|Ubuntu) x=true ;;
		*) warn "Background type were not specified for ${x}"; x=true ;;
	esac
	#=> map temporary x to colorings
	[ "${x}" == rich ] && x=peasoup || x=neon
	COLORING="${x}"
}

resetScreen () { # header
	[ $# -eq 1 ] || wrongArgCount "$@"
	clear
	echo -ne "${NORMAL}> ${PRODUCT} -=- ${1}\n"
	horizon
	echo; echo
}

resume () {
	[ "${RECENT_NAME}" == "${PLAYLIST}" ] && play "" "${RECENT_URL}" || playStream "${RECENT_NAME}" "${RECENT_URL}"
}

saveSettings () {
	$(echo "${COLORING},${PLAYLIST_DIR},${COLLECTION},${RECENT_NAME},${RECENT_URL},${BLINK},${MOD_INFO},${SHUFFLE}" > "${SETTINGS}")
	[ $? -eq 0 ] && echo "Settings saved."
}

setBars () { # nameOfColoring
	[ $# -eq 1 ] || wrongArgCount "$@"
	case "${1}" in
		# TODO add more...
		bee) setBarColors "\e[93m" "${BLACK_BG}" "${BLACK}" "\e[103m" ;;
		c64) setBarColors "\e[38;5;75m" "\e[48;5;4m" "\e[38;5;4m" "\e[48;5;75m" ;;
		crown) setBarColors "\e[38;5;220m" "\e[48;5;1m" "${RED}" "\e[48;5;220m" ;;
		neon) setBarColors "${BLACK}" "\e[48;5;46m" "\e[38;5;201m" "\e[48;5;226m" ;;
		*)	[ "${1}" = forest ] || warn "Tried to set unknown coloring '${1}'"
			setBarColors "${WHITE}" "\e[42m" "\e[90m" "\e[48;5;10m" # default
			;;
	esac
}

setBarColors () { # fgLabels bgLabels fgKeys bgKeys
	[ $# -eq 4 ] || wrongArgCount "$@"
	LABEL_COLOR="${1}${2}"
	KEY_COLOR="${3}${4}"
}

showColors () {
	for c in "${COLORINGS[@]}"; do
		setBars "${c}"
		printf " "
		printUpperBar " ${c} "
	done
	echo
	for c in "${COLORINGS[@]}"; do
		setBars "${c}"
		printf " "
		printLowerBar " ${c} "
	done
	echo
}

start () { # args...
	local plc recent
	plc=true; recent=false
	for arg in "$@"; do
		case "${arg}" in
			--colors*|--help|--license|--settings|--term) batch "${arg}" "$#" ;;
			--log) LOG="./${APPLICATION}.log" ;;
			--no-pl-cache) plc=false ;;
			--recent) recent=true ;;
			--reset) removeSettings ;;
			*) invalidArg "${arg}" ;;
		esac
	done
	# TUI session
	log "*** ${USER} started TUI on $(now)"
	ensureConfig
	ensureCommands "curl" "dialog" "lsb_release" "${PLAYER}"
	ensureInternet
	trap die EXIT
	clearMsg
	PLAYLIST_CACHE="${plc}"
	[ "${recent}" == true ] && resume
	mainMenu
}

streamMenu () { # action
	local c line name url
	local -i dlg
	local -i items
	local -a streams=()
	[ "${#1}" -eq 6 ] || fatal "Invalid action '${1}' in call!"
	c=$(getCollectionPath)
	while IFS=";" read -r line; do
		name="${line%%,*}"
		[ -n "${name}" ] && streams+=("${name}" "${line#$name,}")
	done < "${c}"
	items="${#streams[@]}"
 	if [ "${items}" -eq 0 ]; then
		inform "No Streams in collection."
		return
	fi
	clearMsg
	tput civis || terror
	tryOff
	name=$(dialog \
		--stdout \
		--backtitle "$(getTitle)" \
		--title " ${1} Stream " \
		--clear \
		--ok-label "${1}" \
		--menu "\n${MSG}" 0 0 16 \
		"${streams[@]}"
	)
	dlg=$?
	tryOn
	tput cnorm || terror
   	if [[ "${dlg}" -eq "${DLG_OK}" ]]; then
		# get url from array rather than file again
		for ((i=0; i<items; i=i+2)); do
			if [ "${streams[${i}]}" == "${name}" ]; then
				url="${streams[++i]}"
				break
			fi
		done
		case "${1}" in
			Listen) playStream "${name}" "${url}" ;;
			Remove) removeStream "${name}" "${url}" ;;
			Update) updateStream "${name}" "${url}" || true ;;
			*) invalidArg "${1}" ;;
		esac
	else
		handleDlgReturn "${dlg}"
	fi
}

terror () {
	# TODO Some detailed error handling
	# See https://www.tutorialspoint.com/unix_commands/tput.htm
	error "tput returned $?"
}

tryOff () {
	set +eE
}

tryOn () {
	set -eE
}

updatePlaybackSettings () { # checks...
	[ $# -eq 1 ] || wrongArgCount "$@"
	BLINK=off; MOD_INFO=off; SHUFFLE=off
	for x in ${1}; do
		case "${x}" in
			"${BLINK_ID}") BLINK=on ;;
			"${SHUFFLE_ID}") SHUFFLE=on ;;
			"${MOD_INFO_ID}") MOD_INFO=on ;;
			*) warn "Invalid value ${x} in ${FUNCNAME[0]}" ;;
		esac
	done
	report "Playback preferences updated"
}

updateStream () { # name url
	local err file name url
	resetScreen "Update Stream"
	print "Type an unique name and URL or leave blank to cancel\n\n"
	print "x Collection: ${COLLECTION}\n"
	name=$(inputValidStreamName "${1}")
	[ -z "${name}" ] && return
	url=$(inputValidStreamUrl "${2}")
	[ -z "${url} " ] && return
	file=$(getCollectionPath)
	err=$(sed -i "s|^${1},${2}|${name},${url}|" "${file}" > /dev/null)
	case $? in
		0)	report "Stream updated" ;;
		1)	report "Update stream failed"
			warn "Failed to update '${1},${2}' -> ${err}"
			;;
		*)	warn "Unhandled error $? in ${FUNCNAME[0]}" ;;
	esac
}

usage () {
	echo "*** ${PRODUCT} - ${COPYRIGHT}"
	echo
	echo "Usage: bash ${0} [BATCH | {OPTIONS}]"
	echo "        (no args)       starts the application"
	echo "BATCH:"
	echo "        --colors        show names of available playback bar colorings"
	echo "        --colors=x      change playback bar coloring to x"
	echo "        --help          show this information"
	echo "        --license       show license information only"
	echo "        --settings      show stored settings values"
	echo "        --term          show terminal type"
	echo "OPTIONS:"
	echo "        --log           log some operative information"
	echo "        --no-pl-cache   disable cache when playing lists"
	echo "        --recent        continue recently played list or stream"
	echo "        --reset         clears all stored settings and sets default"
	echo
	echo "For more information please follow the links:"
	echo "[] Getting Started -> https://github.com/jarvenja/tauplayer/"
	echo "[] User Guidelines -> https://jarvenja.github.io/tauplayer/"
	echo "[] License -> https://github.com/jarvenja/tauplayer/blob/main/LICENSE"
}

viewLicense () {
	less "./LICENSE"
}

warn () { # msg
	log "Warning: ${1}"
}

wrongArgCount () { # args...
	local msg
	msg="Wrong number ($#) of arguments {$@} in ${FUNCNAME[1]}!"
	warn "${msg}"
	fatal "${msg}"
}

### App info
readonly APPLICATION="${0::-3}"
readonly VERSION="v0.5 (beta)"
readonly COPYRIGHT="Copyright (c) 2025 Janne Järvenpää <jarvenja@gmail.com>"
readonly PRODUCT_NAME="tau Player"
readonly PRODUCT="${PRODUCT_NAME} ${VERSION}"
### BG Colors
readonly BLACK_BG="\e[40m"
readonly BLOODY_BG="\e[48;5;1m"
readonly BLUE_BG="\e[44m"
readonly BLUE_BG2="\e[48;5;4m"
readonly DARK="\e[38;5;235m"
readonly GREEN_BG1="\e[42m"
readonly GREEN_BG2="\e[102m"
readonly PURPLE_BG="\e[48;5;99m"
readonly UGLY_BG="\e[48;5;65m"
readonly WBG="\e[107m"
### FG Colors
readonly BLACK="\e[30m"
readonly BLOODY="\e[38;5;1m"
readonly BLUE="\e[34m"
readonly GREEN1="\e[38;5;2m"
readonly GREEN2="\e[92m"
readonly RED="\e[1;91m"
readonly YELLOW="\e[0;93m"
readonly WHITE="\e[97m"
### Color bars
declare -a -r COLORINGS=( bee c64 crown forest neon )
readonly WIB="${WHITE}${BLACK_BG}"
### Effects
readonly BLINKI="\e[5m"
readonly BLINKO="\e[25m"
### Dialogs
DIALOGRC=".dialogrc"
export DIALOGRC
readonly DLG_OK=0
readonly DLG_CANCEL=1
readonly DLG_ESC=255
### Checklists
readonly BLINK_ID=1
readonly SHUFFLE_ID=2
readonly MOD_INFO_ID=3
### Symbolic TUI Colors
readonly BAD="${RED}" # errors, missing
readonly BOLD="${GREEN1}"
readonly NORMAL="${GREEN1}"
readonly PLAYING1="${WHITE}"
readonly PLAYING2="${GREEN2}"
readonly WARN="${YELLOW}" # failures, warnings
### Dynamic effects
declare KEY_COLOR= LABEL_COLOR= #=> post initialization
### Special chars
readonly BGR="\u2261"
readonly DASH="\u2500"
readonly ESC=$(printf "\u1b")
### Constant strings
readonly COLLECTION_DIR="./collections"
readonly COLLECTION1="favorites"
readonly FILENAME_CHAR="[a-zA-Z0-9\-]"
readonly GG="https://www.google.com"
readonly PLAYLIST="Playlist"
### Settings
readonly PLAYER="mplayer"
readonly PLAY_PARAMS="-msgcolor -quiet -noautosub -nolirc -ao alsa -afm ffmpeg"
readonly SETTINGS="./${APPLICATION}.cvs"
declare -i -r CACHE_MIN=80
declare -i -r CACHE_SIZE=16384
declare -i -r COLORING_MAX=7
declare BLINK= COLLECTION= COLORING= LOG= MOD_INFO= PLAYLIST_CACHE= PLAYLIST_DIR= RECENT_NAME= RECENT_URL= SHUFFLE= #=> post initialization
### Error policy
set -uo pipefail
tryOn
trap catch ERR
ensureBash
pushd "${PWD}" >/dev/null
start "$@"
