#!/usr/bin/env bash

set -e -u 

Z_FILE="$1"
FILE="${Z_FILE%.z}"

extract_uint() {
	local OFFSET=$1
	head -c $OFFSET "$Z_FILE" | tail -c 4 | od --format u --width=4 --address-radix=n | tr -d ' '
}

# Header size
COMPRESSED_DATA_SIZE=$(extract_uint 20)
COMPRESSED_FILE_SIZE=$(stat --printf="%s" $Z_FILE)
HEADER_SIZE=$((COMPRESSED_FILE_SIZE-COMPRESSED_DATA_SIZE))

# Chunks and their length
declare -a CHUNKS_LEN
for (( CHUNKS=0; CHUNKS*16<=HEADER_SIZE-48; CHUNKS++ )); do
	OFFSET=$((36+CHUNKS*16))
	LEN=$(extract_uint $OFFSET)
	CHUNKS_LEN+=($LEN)
done

# Extract chunks and concatenate
rm -f "$FILE"
OFFSET=$((1+$HEADER_SIZE))
for LEN in "${CHUNKS_LEN[@]}"; do
	{ printf "\x1f\x8b\x08\x00\x00\x00\x00\x00"; tail -c +$OFFSET "$Z_FILE" | head -c $LEN; } | zcat 2> /dev/null >> "$FILE";
	OFFSET=$((OFFSET+LEN))
done

# Assert file size
EXPECTED_FILE_SIZE=$(extract_uint 28)
ACTUAL_FILE_SIZE=$(stat --printf="%s" $FILE)
if [ $ACTUAL_FILE_SIZE -ne $EXPECTED_FILE_SIZE ]; then
	echo "Error: File size mismatch!"
	exit 1
fi