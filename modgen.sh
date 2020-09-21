#!/usr/bin/env bash

MOD_DIR="$1"
MOD_NAME="$2"
MOD_ID="$(basename $MOD_DIR)"
MOD_FILE="$MOD_DIR.mod"
MOD_INFO="$MOD_DIR/mod.info"
MOD_META="$MOD_DIR/modmeta.info"

source "$(dirname $0)/extract.sh"

rm -f "$MOD_FILE"
append_hex $MOD_ID "$MOD_FILE"
append_hex 0 "$MOD_FILE"
append_hex $((${#MOD_NAME}+1)) "$MOD_FILE"
echo -n -e "$MOD_NAME\0" >> $MOD_FILE
MOD_PATH="../../../ShooterGame/Content/Mods/$MOD_ID"
append_hex $((${#MOD_PATH}+1)) "$MOD_FILE"
echo -n -e "$MOD_PATH\0" >> $MOD_FILE
MOD_DESC_LEN=$(extract_uint 0 $MOD_INFO)
MOD_DESC_OFFSET=4
MOD_NUM_LEN=4
tail -c +$((MOD_DESC_LEN+MOD_DESC_OFFSET+1)) "$MOD_INFO" | head -c $((MOD_DESC_LEN+MOD_DESC_OFFSET+MOD_NUM_LEN)) >> "$MOD_FILE"
echo -n -e "\x33\xff\x22\xff\x02\x00\x00\x00\x01" >> "$MOD_FILE"
cat "$MOD_META" >> "$MOD_FILE"
