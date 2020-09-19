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

# Compressed data chunk length and resulting file size
declare -a CHUNKS_LEN
declare -a FILES_SIZE
for (( CHUNKS=0; CHUNKS*16<=HEADER_SIZE-48; CHUNKS++ )); do
	OFFSET=$((32+CHUNKS*16))
	LEN=$(extract_uint $OFFSET)
	CHUNKS_LEN+=($LEN)

	OFFSET=$((OFFSET+8))
	SIZE=$(extract_uint $OFFSET)
	FILES_SIZE+=($SIZE)
done
debug "Debug: Contains $CHUNKS chunks."

# Decompression
rm -f "$FILE"
OFFSET=$((1+$HEADER_SIZE))
TOTAL=0
for (( I=0; I<CHUNKS; I++ )); do
	# Inflate and concatenate
	LEN="${CHUNKS_LEN[I]}"
	{ printf "\x1f\x8b\x08\x00\x00\x00\x00\x00"; tail -c +$OFFSET "$Z_FILE" | head -c $LEN; } | zcat 2> /dev/null >> "$FILE" && echo "Error: Unexpected gzip success!" || debug "Debug: Expected gzip error occured."
	OFFSET=$((OFFSET+LEN))

	# Assert inflated size
	SIZE=${FILES_SIZE[I]}
	TOTAL=$((TOTAL+SIZE))
	EXPECTED=$(stat --printf="%s" $FILE)
	if [ $EXPECTED -ne $TOTAL ]; then
		echo "Error: Chunk $I inflated size does not match!"
		exit 2
	fi
done

echo "Success: Inflated $Z_FILE."