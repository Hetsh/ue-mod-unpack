#!/usr/bin/env bash

extract_uint() {
	local WIDTH=4
	local OFFSET=$1
	local FILE="$2"
	head -c $((OFFSET+WIDTH)) "$FILE" | tail -c $WIDTH | od --format u --width=$WIDTH --address-radix=n | tr -d ' '
}

append_hex() {
	local WIDTH=4
	local HEX=$(printf "%0$((WIDTH*2))X" "$1")
	local HEX_BE=$(echo ${HEX:6:2}${HEX:4:2}${HEX:2:2}${HEX:0:2} | sed -e 's/../\\x&/g')
	local FILE="$2"
	echo -n -e "$HEX_BE" >> "$FILE"
}
