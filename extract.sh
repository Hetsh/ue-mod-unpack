#!/usr/bin/env bash

extract_uint() {
	local WIDTH=4
	local FILE="$1"
	local OFFSET=$2
	head -c $((OFFSET+WIDTH)) "$FILE" | tail -c $WIDTH | od --format u --width=$WIDTH --address-radix=n | tr -d ' '
}
