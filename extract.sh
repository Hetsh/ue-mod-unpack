#!/usr/bin/env bash

extract_uint() {
	local WIDTH=4
	local OFFSET=$1
	local FILE="$2"
	head -c $((OFFSET+WIDTH)) "$FILE" | tail -c $WIDTH | od --format u --width=$WIDTH --address-radix=n | tr -d ' '
}
