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
	file=$(getStreamGroupPath "${STREAM_GROUP}")
	$(echo "${1},${2}" >> "${file}") && sort -o "${file}"{,}
}

archive () { # streamGroup
	local bak f
	f=$(getStreamGroupPath "${1}")
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
		--codex) showCodexInfo ;;
		--colors) showColors ;;
		--colors=*) changeColors "${1:9}" ;;
		--help) usage ;;
		--license) viewLicense ;;
		--log) showLog ;;
		--settings) loadSettings "${SETTINGS}" ; printSettings ;;
		--term) echo "Your terminal type is '${TERM}' which may affect to see correct colors or characters." ;;
		*) invalidArg "${1}" ;;
	esac
	popd > /dev/null
	exit 0
}

catch () {
	local code cmd lineno
	code=$?
	cmd="${BASH_COMMAND}"
	lineno="${BASH_LINENO}"
	printf "${WARN}The line %d: %s\nreturned %d\n" "${lineno}" "${cmd}" "${code}"
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

createStreamGroup () { # validName
	local f
	f=$(getStreamGroupPath "${1}")
	if [ -f "${f}" ]; then
		fatal "File ${f} already exists!"
	else
		touch "${f}"
		[ $? -ne 0 ] && fatal "Couldn\'t create stream group ${1}!"
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
		echo -ne "\n${APPLICATION} requires the following commands to operate: ${BAD}${cmds}\e[0m\n"
		echo "Please install missing dependencies and try again."
		echo "=> sudo apt update && sudo apt-get install ${cmds}"
		fatal "Missing dependencies"
	fi
}

ensureConfig () {
	[ -f "${DIALOGRC}" ] || fatal ".dialogrc file not found in directory!"
	ensureDir "${LOG_DIR}"
	ensureDir "${STREAM_GROUP_DIR}"
	BLINK=true
	if [ -f "${SETTINGS}" ]; then
		loadSettings "${SETTINGS}"
	else #=> ensure tauplayer.cvs and ./streams/favorites.cvs
		touch $(getStreamGroupPath "${STREAM_GROUP1}")
		PLAYLIST_DIR="${HOME}"
		STREAM_GROUP="${STREAM_GROUP1}"
		saveSettings
	fi
}

ensureDir () { # dir
	[ $# -eq 1 ] || wrongArgCount "$@"
	[ -d "${1}" ] || mkdir "${1}"
}

ensureFile () { # file
	[ -f "${1}" ] || fatal "File ${1} not found!"
}

ensureInternet () {
	local code
	code=$(getHttpResponseStatus "${GG}")
	[ "${code}" = 200 ] || fatal "No connection available to reach ${GG}!"
}

error () { # msg
	echo -ne " ${WARN}Error: ${1}$\e[0m" >&2
}

fail () { # reason
	echo -ne " ${WARN}[${1}]\e[0m\n"
	# inputKey
}

fatal () { # msg
	local msg
	msg="Fatal Error: ${1}"
	log "${msg}"
	echo -e "${BAD}${msg}\e[0m" >&2
	exit 1
}

getBackupPath () { # streamGroupName
	local initial path
	initial="${STREAM_GROUP_DIR}/${1}"
	path="${initial}.bak"
	for ((i=1; -f "${path}" ;i++)); do
		path="${initial}-${i}.bak"
	done
	echo "${path}"
}

getDistributor () {
	local did
	did=$(lsb_release -i)
	echo "${did:16}"
}

getHttpResponse () { # url
	local check code prefix reason sign
	[ $# -eq 1 ] || wrongArgCount "$@"
	resetScreen
	echo -ne "Testing..."
	code=$(getHttpResponseStatus "${1}")
	case "${code}" in
		200|302|400|404|405) check=x ;;
		*) check=- ;;
	esac
	reason=$(getHttpResponseName "${code}")
	log "[${check}] ${code} ${reason} <- ${1}"
	report "${code} ${reason} [${check}]"
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
	# code=$(curl -o /dev/null --silent --head --write-out "%{http_code}\n" "${1}")
	echo "${code}"
}

getKeyValue () { # key
	local f value
	f=$(getStreamGroupPath "${STREAM_GROUP}")
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

getStreamGroupPath () { # streamGroupName
	[ $# -eq 1 ] || wrongArgCount "$@"
	echo "${STREAM_GROUP_DIR}/${1}.cvs"
}

handleDlgReturn () { # dlgReturnValue
	case "${1}" in
 		"${DLG_CANCEL}"|"${DLG_ESC}") ;; # normally ignored
 		 *) warn "Unhandled dialog return code ${1} in ${FUNCNAME[1]}" ;;
	esac
}

hasKey () { # key
	local f match
	f=$(getStreamGroupPath "${STREAM_GROUP}")
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

initCodexInfo () {
	CODEX_RECORD=false
	if [ ! -f "${CODEX_FILE}" ]; then
		touch "${CODEX_FILE}" && CODEX_RECORD=true
	fi
}

inputKey () {
	echo -ne "${HIDE_CURSOR}\n\n"
	print ">> Press a key to continue..."
	read -rsn 1
}

inputNewStream () {
	local err name url
	resetScreen "Add New Stream"
	print "Type an unique name and URL or leave blank to cancel\n\n"
	print "x ${STREAM_GROUP}: ${STREAM_GROUP}\n"
	name=$(inputValidStreamName)
	[ -z "${name}" ] && return
	url=$(inputValidStreamUrl)
	[ -z "${url}" ] && return
	$(addValidStream "${name}" "${url}")
	if [ $? -eq 0 ]; then
		inform "Stream added.\n"
		log "Added '${name},${url}' into ${STREAM_GROUP}"
	fi
}

inputNewStreamGroup () {
	local file key name
	key="?"; name=""
	resetScreen "New Stream Group"
	print "Type an unique name for stream group.\n"
	print "- Only letters, numbers and dash (-) are allowed.\n"
	print "- Use left arrow [<-] to remove last letter.\n"
	print "- Leave it empty to cancel\n\n"
	print "> Stream Group Name: "
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
	file=$(getStreamGroupPath "${name}")
	if [ -f "${file}" ]; then
		fail "Already exists"
		inputKey
	else
		createStreamGroup "${name}"
		STREAM_GROUP="${name}"
		report "New stream group changed"
	fi
}

inputValidStreamName () { # [old]
	local url
	while :; do
		read -r -p "  Name: " -i "${1:-}" -e name
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
	read -r -p "   URL: " -i "${1:-}" -e url
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
	local file pld streamGroup
	[ $# -eq 1 ] || wrongArgCount "$@"
	IFS=, read COLORING pld streamGroup RECENT_NAME RECENT_URL SHUFFLE < "${1}"
	unset IFS
	[ -d "${pld}" ] && PLAYLIST_DIR="${pld}" || PLAYLIST_DIR="${HOME}"
	# ensure there is stream group..
	STREAM_GROUP="${STREAM_GROUP1}"
	if [[ -n "${streamGroup}" ]]; then
		file=$(getStreamGroupPath "${streamGroup}")
		[ -f "${file}" ] && STREAM_GROUP="${streamGroup}"
	fi
	# set coloring dependent values..
	[ -z "${COLORING}" ] || [ "${#COLORING}" -gt "${COLORING_MAX}" ] && resetColoring
	setBars "${COLORING}" || true
	# ensure playback preferences..
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
			"a" "Audio Settings..." \
			"c" "Playback Controls..." \
			# "p" "Playback preferences..." \
			"l" "Play lists..." \
			"r" "Radio Streams..." \
			"v" "View license..."
		)
		tput civis || terror
		tryOff
		choice=$(dialog \
			--stdout \
			--backtitle "${TITLE_BAR}" \
			--title "" \
			--clear \
			--cancel-label "Exit" \
			--ok-label "Select" \
			--menu "${MSG}" 0 40 "${MIN_HEIGHT}" \
 			"${menu[@]}"
		)
    	dlg=$?
		tryOn
		tput cnorm || terror
		clearMsg
		if [[ "${dlg}" -eq "${DLG_OK}" ]]; then
			case "${choice}" in
		    	a) alsamixer ;;
				c) printPlaybackControls ;;
				# p) playbackMenu || true ;;
				l) playList || true ;;
				r) radioStreamsMenu || true ;;
				v) viewLicense || true ;;
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

parseIcyInfo () { # icyInfoLine
	[ $# -eq 1 ] || wrongArgCount "$@"
	IFS=';' read title url <<< "${1:23}" # cuts "ICY Info: StreamTitle='"
	unset IFS
	STREAM_TITLE="${title::-1}"
	if [ -z "${url}" ]; then
		STREAM_URL="${ICY_PLACEHOLDER}"
	else
		url="${url::-1}"
		url="${url:11}" # cuts "StreamUrl=\'"
		if [[ "${url}" != "${STREAM_URL}" ]]; then # log only changes
			log "@ ${url}"
			STREAM_URL="${url}"
		fi
	fi
	log "> ${STREAM_TITLE}"
}

play () { # [streamName] url
	local alsa audio cmd good line prev refresh video
	local -A events
	local -a lines playback
	for ((i=12;i<=22;++i)); do lines[${i}]=""; done
	playback=()	
	alsa=true
	good=true
	refresh=true
	prev=""
	if [ -z "${1}" ]; then # play list
		[ "${PLAYLIST_CACHE}" == true ] && playback+=(-cache "${CACHE_SIZE}" -cache-min "${CACHE_MIN}")
		[ "${SHUFFLE}" == on ] && playback+=(-shuffle)
		playback+=(-playlist)
		RECENT_NAME="${PLAYLIST_KEY}"
	else
		RECENT_NAME="${1}"
	fi
	RECENT_URL="${2}"
	STREAM_TITLE="${ICY_PLACEHOLDER}"
	STREAM_URL="${ICY_PLACEHOLDER}"
	cmd="${PLAYER_CMD} ${PLAY_PARAMS} ${playback[*]} ${2}"
	tryOff # since interaction with 3rd party modules
	$(echo -ne "${cmd}") |
	{	echo -ne "${HIDE_CURSOR}"
		log "Started playback session for ${2}"
		while IFS= read -r line; do
			line=$(unformat "${line}")
			case "${line}" in
				"Audio only"*) audio=true ;;
				" Album:"*) lines[12]="${COLUMN1}${line/:/      ${COLUMN2}}" ;;
				" Artist:"*) lines[13]="${COLUMN1}${line/:/     ${COLUMN2}}" ;;
				" Comment:"*) lines[14]="${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				" Genre:"*) lines[15]="${COLUMN1}${line/:/      ${COLUMN2}}" ;;
				" Title:"*) lines[16]="${COLUMN1}${line/:/      ${COLUMN2}}" ;;
				" Year:"*) lines[17]="${COLUMN1}${line/:/       ${COLUMN2}}" ;;
				"Name   :"*) lines[12]=" ${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				"Genre  :"*) lines[13]=" ${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				"Public :"*) lines[14]=" ${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				"Website:"*) lines[15]=" ${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				"Bitrate:"*) lines[16]=" ${COLUMN1}${line/:/    ${COLUMN2}}" ;;
				"Cache fill:"*) CACHE_FILL="${line}" ;;
				"Cache size"*) CACHE_SIZE_MSG="${line}" ;;
				"Clip Info:"*) ;;
				Connecting*|Resolving*) log "${line}" ;;
				"ICY Info:"*) parseIcyInfo "${line}" ;;
				MPlayer*) PLAYER_VER="${line}" ;;
				Playing*) refresh=true ;;
				"Starting playback...") ;;
				"Video: no video"*) video=false ;;
				*Volume:*) lines[20]=$(printScale "${line:7}") ;;
				AO:*|AUDIO:*|libav*|Opening*|Selected*|Trying*|=*)
					if [ "${CODEX_RECORD}" == true ]; then
						echo "${line}" >> "${CODEX_FILE}"
						case "${line}" in AO:*)
							log "Finished recording ${CODEX_FILE}"
							CODEX_RECORD=false
							;;
						esac
					fi
					;;
				"[AO_ALSA]"*|"Cache empty"*)
					if [ "${events[${line}]}" ]; then : # skip
					else
						events["${line}"]=1
						log "${line}"
						echo -ne "${YELLOW}${line}\e[0m\n"
					fi
					;;
				"[mp3floats"*)
					log "${line}"
					if [[ "${good}" == true ]]; then
						good=false
						echo -ne "${YELLOW}[Quality Problems]\e[0m\n"
					fi
					;;
				*)	#if [[ ${line} =~ Volume: ]]; then
					#	lines[20]=$(printScale "${line:7}")
					#else 
						echo -ne "${line}"	
					#fi

					#	echo -ne "${line}\n"
					#if [ "${line}" != "${prev}" ]; then
					#	prev="${line}"
					#	echo -ne "${line}\n"
					#fi
					;;
			esac
			if [ "${refresh}" == true ]; then
				clear 
				echo -ne "${GREEN2}${TITLE_BAR}\n"
				horizon
				echo ; echo
				if [ "${RECENT_NAME}" == "${PLAYLIST_KEY}" ]; then
					printLocalKeys
					lines[7]=" ${COLUMN1}Playlist    ${COLUMN2}${RECENT_URL}"
				else # stream
					printStreamKeys
					lines[7]=" ${COLUMN1}Group       ${COLUMN2}${STREAM_GROUP}"
					lines[8]=" ${COLUMN1}Key         ${COLUMN2}${RECENT_NAME}"
					lines[9]=" ${COLUMN1}URL         ${COLUMN2}${RECENT_URL}"
					lines[10]=" ${COLUMN1}StrTitle    ${COLUMN2}${STREAM_TITLE}"
					lines[11]=" ${COLUMN1}StreamURL   ${COLUMN2}${STREAM_URL}"
				fi
				echo
				for i in "${lines[@]}"; do
					echo -ne "${i}\n"
				done
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
		--backtitle "${TITLE_BAR}" \
		--title " Playback Preferences " \
		--clear \
		--ok-label "Update" \
		--checklist "\nUse arrow keys and space bar" 0 34 6 \
		"${SHUFFLE_ID}" "Shuffle playlist" "${SHUFFLE}" \
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
			--backtitle "${TITLE_BAR}" \
			--title " Playlists found " \
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

# printf '%s|' "${array[@]}

print () { # line
	[ $# -eq 1 ] || wrongArgCount "$@"
	echo -ne " ${GREEN2}${1}\e[0m\n" # create one space margin
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

printPlaybackControls () {
	resetScreen
	print "${GREEN1}Keys when playing local files through playlist:\n"
	printLocalKeys
	echo ; echo
	print "${GREEN1}Keys when playing radio streams:\n"
	printStreamKeys
	echo ; echo
	print "${GREEN1}Avoid pressing any other keys during playback.\n"
	inputKey
}

printScale () { # infoLine
	local -i bars
	[ $# -eq 1 ] || wrongArgCount "$@"
	IFS=':' read label rest <<< "${1}"
	IFS="%. " read percent bytes <<< "${rest}"
	unset IFS
	# log "|${label}|${percent}|${bytes}|"
	# float=$((bc -l <<< "${percent}/2"))
	# log "float=${float}"
	# bars=${float%.*}
	bars="$((${percent}/2))"
	echo -ne "${GREEN2} ${label} "
	for ((i=0; i<"${bars}"; i++)); do echo -ne '|'; done
	echo -ne "${DARK_GRAY}"
	for ((i="${bars}"; i<50; i++)); do echo -ne '|'; done
	echo -ne " \e[39m"
}

printSettings () {
	local -a vars
	vars=(COLORING PLAYLIST_DIR RECENT_NAME RECENT_URL SHUFFLE STREAM_GROUP)
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

radioStreamsMenu () {
	local choice
	local -i dlg
	local -a entries
	while :; do
		entries=( \
			"s" "Select Stream..." \
			"a" "Add Stream into Group..." \
			"c" "Change Stream Group..." \
			"n" "Create New Group..." \
			"r" "Remove Group from list..."
		)
		tput civis || terror
		tryOff
		choice=$(dialog \
			--stdout \
	 		--backtitle "${TITLE_BAR}" \
	 		--title " ${STREAM_GROUP} " \
	 		--clear \
			--ok-label "Select" \
			--menu "\n${MSG}" 0 0 "${MIN_HEIGHT}" \
			"${entries[@]}"
		)
		dlg=$?
		tryOn
		tput cnorm || terror
		if [ "${dlg}" -eq "${DLG_OK}" ]; then
			case "${choice}" in
				s) streamSelectionMenu || true ;;
				a) inputNewStream || true ;;
				c) streamGroupMenu "Change" || true ;;
				n) inputNewStreamGroup || true ;;
				r) streamGroupMenu "Remove" || true ;;
				*) invalidArg "${arg}" ;;
			esac
		else
			handleDlgReturn "${dlg}"
			break
		fi
	done
}


removeCodexInfo () {
	rm "${CODEX_FILE}" && log "Codex info cleared."
}

removeKey () { # key value filepath
	$(sed -i '/^$1,/s/.*/${2}/' "${3}")
}

removeSettings () {
	rm "${SETTINGS}" && log "Settings cleared."
}

removeStream () { # name url
	local file
	file=$(getStreamGroupPath "${STREAM_GROUP}")
	$(sed -i "/${1}/d" "${file}")
	if [ $? -eq 0 ]; then
		report "Stream removed"
	else
		fatal "Failed ($?) to remove stream '${1}' with data '${2}'"
	fi
}

removeStreamGroup () {
	local c
	c=$(streamGroupMenu "Remove")
	[ -n "${c}" ] && archiveFile getStreamGroupPath "${c}"
}

replaceKeyValue () { # key value filepath
	$(sed -i '/^$1,/s/.*/${2}/' "${3}")
	[ $? -eq 0 ] || error "Unable to update key '${1}'!"
}

report () { # msg
	[ $# -eq 1 ] || wrongArgCount "$@"
	MSG="-> ${1}"
}

resetColoring () {
	local x
	x=$(getDistributor)
	case "${x}" in
		# TODO add more
		Linuxmint) x=rich ;;
		Raspian) x=true ;;
		Ubuntu) x=true ;;
		*) warn "Background type were not specified for ${x}"; x=true ;;
	esac
	#=> map temporary x to colorings
	# [ "${x}" == rich ] && x=forest || x=forest
	x=forest
	COLORING="${x}"
}

resetScreen () {
	clear
	echo -ne "${GREEN2}${TITLE_BAR}\n"
	horizon
	echo ; echo	
}

resume () {
	[ "${RECENT_NAME}" == "${PLAYLIST}" ] && play "" "${RECENT_URL}" || play "${RECENT_NAME}" "${RECENT_URL}"
}

saveSettings () {
	$(echo "${COLORING},${PLAYLIST_DIR},${STREAM_GROUP},${RECENT_NAME},${RECENT_URL},${SHUFFLE}" > "${SETTINGS}")
	[ $? -eq 0 ] && echo "Settings saved."
}

setBarColors () { # fgLabels bgLabels fgKeys bgKeys
	[ $# -eq 4 ] || wrongArgCount "$@"
	LABEL_COLOR="${1}${2}"
	KEY_COLOR="${3}${4}"
}

setBars () { # nameOfColoring
	[ $# -eq 1 ] || wrongArgCount "$@"
	case "${1}" in
		# TODO add more...
		c64) setBarColors "\e[38;5;75m" "\e[48;5;4m" "\e[38;5;4m" "\e[48;5;75m" ;;
		crown) setBarColors "\e[38;5;220m" "\e[48;5;1m" "${RED}" "\e[48;5;220m" ;;
		neon) setBarColors "\e[38;5;201m" "\e[48;5;226m" "\e[38;5;21m" "\e[48;5;46m" ;;
		*)	[ "${1}" = forest ] || warn "Tried to set unknown coloring '${1}'"
			setBarColors "${WHITE}" "\e[42m" "\e[90m" "\e[48;5;10m" # set default
			;;
	esac
}

showCodexInfo () {
	[ -f "${CODEX_FILE}" ] && cat "${CODEX_FILE}" || echo "No codex info available. It will be recorded next time when you play something."
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

showLog () {
	cat "${LOG}"
}

start () { # args...
	local plc recent
	plc=true; recent=false
	for arg in "$@"; do
		case "${arg}" in
			--codex|--colors*|--help|--license|--log|--settings|--term) batch "${arg}" "$#" ;;
			--no-log) LOG="" ;;
			--no-pl-cache) plc=false ;;
			--recent) recent=true ;;
			--reset) removeCodexInfo && removeSettings ;;
			*) invalidArg "${arg}" ;;
		esac
	done
	# TUI session
	log "*** ${USER} started TUI on $(now)"
	ensureConfig
	ensureCommands "curl" "dialog" "lsb_release" "${PLAYER_CMD}"
	# ensureInternet
	trap die EXIT
	initCodexInfo
	clearMsg
	PLAYLIST_CACHE="${plc}"
	[ "${recent}" == true ] && resume
	mainMenu
}

streamActionMenu () { # streamName streamUrl
	local available choice code listen name reason url
	local -i dlg
	local -a actions=()
	[ $# -eq 2 ] || wrongArgCount "$@"
	#listen="Listen"
	#code=$(getHttpResponseStatus "${2}")
	#case "${code}" in
	#	200|302|400|404|405) available=false ;;
	#	*) listen+=" (anyway)" ;;
	# esac
	# reason=$(getHttpResponseName "${code}")
	# report "${code} ${reason}"
	clearMsg
	while :; do
		tput civis || terror
		tryOff
		actions=( \
			"l" "Listen" \
			"g" "Get HTTP status" \
			"e" "Edit details" \
			"r" "Remove from group" \
		)
		choice=$(dialog \
			--stdout \
			--backtitle "${TITLE_BAR}" \
			--title " ${1} " \
			--clear \
			--ok-label "Select" \
			--menu "\n${MSG}" 0 0 "${MIN_HEIGHT}" \
			"${actions[@]}"
		)
		dlg=$?
	 	tryOn
		tput cnorm || terror
		clearMsg		
		if [[ "${dlg}" -eq "${DLG_OK}" ]]; then
			case "${choice}" in
				l) play "${1}" "${2}" || true ;;
				g) getHttpResponse "${2}" || true ;;
				e) updateStream "${1}" "${2}" || true ;;
				r) removeStream "${1}" "${2}" ;;
				*) invalidArg "${choice}" ;;
			esac
		else
			handleDlgReturn "${dlg}"
			break
		fi
	done
}

streamGroupMenu () { # action
	local group line
	local -i dlg
	local -a entries
	[ $# -eq 1 ] || wrongArgCount "$@"
	while read -r line; do
		group="${line##*/}"
		group="${group%.cvs}"
		[ "${group}" == "${STREAM_GROUP}" ] || entries+=("${group}" "")
		done < <(find "${STREAM_GROUP_DIR}" -name "*.cvs" | sort)
    [ "${#entries[@]}" -eq 0 ] && fatal "No stream groups found in ${STREAM_GROUP_DIR}."
	clearMsg
	tput civis || terror
	tryOff
	group=$(dialog \
		--stdout \
 		--backtitle "${TITLE_BAR}" \
 		--title " ${1} Stream Group " \
 		--clear \
		--ok-label "Select" \
		--menu "\n${MSG}" 0 0 "${MIN_HEIGHT}" \
		"${entries[@]}"
	)
	dlg=$?
	tryOn
	tput cnorm || terror
	if [ "${dlg}" -eq "${DLG_OK}" ]; then
		case "${1}" in
			Change) STREAM_GROUP="${group}" ; report "Stream Group changed." ;;
			Remove) archive "${group}" ;;
			*) invalidArg "${1}" ;;
		esac
	else
		handleDlgReturn "${dlg}"
	fi
}

streamSelectionMenu () {
	local name sgp url
	local -i dlg
	local -i items
	local -a streams=()
	sgp=$(getStreamGroupPath "${STREAM_GROUP}")
	while IFS=";" read -r line; do
		name="${line%%,*}"
		[ -n "${name}" ] && streams+=("${name}" "${line#$name,}")
	done < "${sgp}"
	items="${#streams[@]}"
 	if [ "${items}" -eq 0 ]; then
		report "No streams in group."
		# FixMe!
		return
	fi
	while :; do
		clearMsg
		tput civis || terror
		tryOff
		name=$(dialog \
			--stdout \
			--backtitle "${TITLE_BAR}" \
			--title " ${STREAM_GROUP} " \
			--clear \
			--ok-label "Select" \
			--menu "\n${MSG}" 0 0 0 \
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
			streamActionMenu "${name}" "${url}"
		else
			handleDlgReturn "${dlg}"
			break
		fi
	done
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

unformat () { # formattedLine
	[ $# -eq 1 ] || wrongArgCount "$@"
	echo "${1}" | sed -r "s/[[:cntrl:]]\[([0-9]{1,3};)*[0-9]{1,3}m//g"	
}

updatePlaybackSettings () { # checks...
	[ $# -eq 1 ] || wrongArgCount "$@"
	SHUFFLE=off
	for x in ${1}; do
		case "${x}" in
			"${SHUFFLE_ID}") SHUFFLE=on ;;
			*) warn "Invalid value ${x} in ${FUNCNAME[0]}" ;;
		esac
	done
	report "Playback preferences updated"
}

updateStream () { # name url
	local err file name url
	resetScreen "Update Stream"
	print "Type an unique name and URL or leave blank to cancel\n\n"
	print "Group: ${STREAM_GROUP}"
	name=$(inputValidStreamName "${1}")
	[ -z "${name}" ] && return
	url=$(inputValidStreamUrl "${2}")
	[ -z "${url} " ] && return
	file=$(getStreamGroupPath "${STREAM_GROUP}")
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
	echo "        --codex         show codecs info"
	echo "        --colors        show names of available playback bar colorings"
	echo "        --colors=<name> change playback bar coloring by name"
	echo "        --help          show this information"
	echo "        --license       show license information only"
	echo "        --log           show logged information"
	echo "        --settings      show stored settings values"
	echo "        --term          show terminal type"
	echo "OPTIONS:"
	echo "        --no-log        disable logging operative information"
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
readonly VERSION="v0.6 (beta)"
readonly COPYRIGHT="Copyright (c) 2025 <jarvenja@gmail.com>"
readonly PRODUCT_NAME="tau Player"
readonly PRODUCT="${PRODUCT_NAME} ${VERSION}"
### BG Colors
readonly BLACK_BG="\e[40m"
readonly BLUE_BG="\e[44m"
readonly BLUE_BG2="\e[48;5;4m"
#readonly DARK="\e[38;5;235m"
readonly GREEN_BG1="\e[42m"
readonly GREEN_BG2="\e[102m"
readonly PURPLE_BG="\e[48;5;99m"
# readonly WBG="\e[107m"
### FG Colors
readonly BLACK="\e[30m"
readonly BLUE="\e[34m"
readonly DARK_GRAY="\e[90m"
readonly GREEN1="\e[38;5;2m"
readonly GREEN2="\e[92m"
readonly RED="\e[1;91m"
readonly YELLOW="\e[0;93m"
readonly WHITE="\e[97m"
### Color bars
declare -a -r COLORINGS=( c64 crown forest neon ) #=> enabled
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
### Numbers
declare -i -r MIN_HEIGHT=8
readonly SHUFFLE_ID=1
### Symbolic TUI Colors
declare KEY_COLOR= LABEL_COLOR= #=> post initialization
readonly COLUMN1="${GREEN1}"
readonly COLUMN2="${GREEN1}"
readonly BAD="${RED}" # errors, missing
readonly PLAYING="${WHITE}"
readonly WARN="${YELLOW}" # failures, warnings
### Special chars
readonly BGR="\u2261"
readonly DASH="\u2500"
readonly ESC=$(printf "\u1b")
readonly HIDE_CURSOR="\e[?25l"
### Constant strings
readonly BROADCAST="${WHITE}${BLINKI}((${BLINKO} A ${BLINKI}))${BLINKO}"
readonly FILENAME_CHAR="[a-zA-Z0-9\-]"
readonly GG="https://www.google.com"
readonly ICY_PLACEHOLDER="n/a"
readonly PLAYLIST="Playlist"
readonly PLAYLIST_KEY=""
readonly PLAY_SIGN="PLAY >"
readonly STREAM_GROUP_DIR="./streams"
readonly STREAM_GROUP1="favorites"
readonly TITLE_BAR="> ${PRODUCT} -=- ${COPYRIGHT}"
### Settings
declare -i -r CACHE_MIN=80
declare -i -r CACHE_SIZE=16384
declare -i -r COLORING_MAX=7
readonly CODEX_FILE="./codex.txt"
readonly PLAYER_CMD="mplayer"
readonly PLAY_PARAMS="-msgcolor -quiet -noautosub -nolirc -ao alsa -afm ffmpeg"
readonly SETTINGS="./${APPLICATION}.cvs"
readonly LOG_DIR="./logs"
declare LOG="${LOG_DIR}/${APPLICATION}.log"
declare BLINK= CACHE_FILL= CACHE_SIZE_MSG= CODEX_RECORD= COLORING= PLAYER_VER= PLAYLIST_CACHE= PLAYLIST_DIR= 
declare RECENT_NAME= RECENT_URL= SHUFFLE= STREAM_GROUP= STREAM_TITLE= STREAM_URL= VOLUME_PID=
### Error policy
set -uo pipefail
tryOn
trap catch ERR
ensureBash
pushd "${PWD}" >/dev/null
start "$@"
