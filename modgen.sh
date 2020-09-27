#!/usr/bin/env bash

set -e -u

MOD_DIR="$1"
MOD_NAME="$2"
MOD_ID="$(basename $MOD_DIR)"
MOD_FILE="$MOD_DIR.mod"
MOD_INFO="$MOD_DIR/mod.info"
MOD_META="$MOD_DIR/modmeta.info"

source "$(dirname $0)/extract.sh"

# Cleanup
rm -f "$MOD_FILE"

# Basic info
append_hex $MOD_ID "$MOD_FILE"
append_hex 0 "$MOD_FILE"
MOD_NAME_LEN=$((${#MOD_NAME}+1))
append_hex "$MOD_NAME_LEN" "$MOD_FILE"
echo -n -e "$MOD_NAME\0" >> $MOD_FILE
MOD_PATH="../../../ShooterGame/Content/Mods/$MOD_ID"
MOD_PATH_LEN=$((${#MOD_PATH}+1))
append_hex "$MOD_PATH_LEN" "$MOD_FILE"
echo -n -e "$MOD_PATH\0" >> $MOD_FILE

# Data from mod.info
MAP_NAME_OFFSET=4
MAP_NAME_LEN=$(extract_uint 0 $MOD_INFO)
MAP_NUM_OFFSET=$((MAP_NAME_OFFSET+MAP_NAME_LEN))
MAP_NUM_LEN=4
MAP_NUM=$(extract_uint $MAP_NUM_OFFSET $MOD_INFO)
append_hex "$MAP_NUM" "$MOD_FILE"
MOD_IDK_OFFSET=$((MAP_NUM_OFFSET+MAP_NUM_LEN))
MOD_IDK_LEN=$(extract_uint $MOD_IDK_OFFSET $MOD_INFO)
tail -c +$((MOD_IDK_OFFSET+1)) "$MOD_INFO" | head -c $((MAP_NUM_LEN+MOD_IDK_LEN)) >> "$MOD_FILE"

# Byte magic
echo -n -e "\x33\xff\x22\xff\x02\x00\x00\x00\x01" >> "$MOD_FILE"

# Data from modmeta.info
cat "$MOD_META" >> "$MOD_FILE"
