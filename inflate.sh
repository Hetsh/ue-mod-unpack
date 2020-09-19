#!/usr/bin/env bash

set -e -u 

Z_FILE="$1"
FILE="${Z_FILE%.z}"

debug() {
	#true
	echo $1
}

extract_uint() {
	local WIDTH=4
	local OFFSET=$1
	head -c $((OFFSET+WIDTH)) "$Z_FILE" | tail -c $WIDTH | od --format u --width=$WIDTH --address-radix=n | tr -d ' '
}

# Assert signature
SIGVER=$(extract_uint 0)
if [ $SIGVER -ne 2653586369 ]; then
	echo "Error: Signature mismatch!"
	exit 1
fi
debug "Debug: Signature verified."

# Header size
COMPRESSED_DATA_SIZE=$(extract_uint 16)
COMPRESSED_FILE_SIZE=$(stat --printf="%s" $Z_FILE)
HEADER_SIZE=$((COMPRESSED_FILE_SIZE-COMPRESSED_DATA_SIZE))
debug "Debug: Header size is $HEADER_SIZE bytes."

# Chunks and their length
declare -a CHUNKS_LEN
for (( CHUNKS=0; CHUNKS*16<=HEADER_SIZE-48; CHUNKS++ )); do
	OFFSET=$((32+CHUNKS*16))
	LEN=$(extract_uint $OFFSET)
	CHUNKS_LEN+=($LEN)
done
debug "Debug: Contains $CHUNKS chunks."

# Extract chunks and concatenate
rm -f "$FILE"
OFFSET=$((1+$HEADER_SIZE))
for LEN in "${CHUNKS_LEN[@]}"; do
	{ printf "\x1f\x8b\x08\x00\x00\x00\x00\x00"; tail -c +$OFFSET "$Z_FILE" | head -c $LEN; } | zcat >> "$FILE" || true
	OFFSET=$((OFFSET+LEN))
done

# Assert file size
EXPECTED_FILE_SIZE=$(extract_uint 24)
ACTUAL_FILE_SIZE=$(stat --printf="%s" $FILE)
if [ $ACTUAL_FILE_SIZE -ne $EXPECTED_FILE_SIZE ]; then
	echo "Error: File size mismatch!"
	exit 1
fi

echo "Success: Inflated $Z_FILE."