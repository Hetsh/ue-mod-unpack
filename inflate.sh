#!/usr/bin/env bash

set -e -u

Z_FILE="$1"
FILE="${Z_FILE%.z}"

debug() {
	true
	#echo $1
}

source "$(dirname $0)/extract.sh"

# Assert signature
SIGVER=$(extract_uint 0 $Z_FILE)
if [ $SIGVER -ne 2653586369 ]; then
	echo "Error: Signature mismatch"
	exit 1
fi
debug "Debug: Signature verified"

# Header size
COMPRESSED_DATA_SIZE=$(extract_uint 16 $Z_FILE)
COMPRESSED_FILE_SIZE=$(stat --printf="%s" $Z_FILE)
HEADER_SIZE=$((COMPRESSED_FILE_SIZE-COMPRESSED_DATA_SIZE))
debug "Debug: Header size is $HEADER_SIZE bytes"

# Compressed data chunk length and resulting file size
declare -a CHUNKS_LEN
declare -a FILES_SIZE
for (( CHUNKS=0; CHUNKS*16<=HEADER_SIZE-48; CHUNKS++ )); do
	OFFSET=$((32+CHUNKS*16))
	LEN=$(extract_uint $OFFSET $Z_FILE)
	CHUNKS_LEN+=($LEN)

	OFFSET=$((OFFSET+8))
	SIZE=$(extract_uint $OFFSET $Z_FILE)
	FILES_SIZE+=($SIZE)
done
debug "Debug: Contains $CHUNKS chunks"

# Decompression
rm -f "$FILE"
OFFSET=$((1+$HEADER_SIZE))
EXPECTED=0
for (( I=0; I<CHUNKS; I++ )); do
	CHUNK_NR=$((I+1))

	# Inflate and concatenate
	LEN="${CHUNKS_LEN[I]}"
	{ printf "\x1f\x8b\x08\x00\x00\x00\x00\x00"; tail -c +$OFFSET "$Z_FILE" | head -c $LEN; } | zcat 2> /dev/null >> "$FILE" && echo "Error: Unexpected success inflating chunk $CHUNK_NR" && exit 2 || debug "Debug: Expected error inflating chunk $CHUNK_NR"
	OFFSET=$((OFFSET+LEN))

	# Assert inflated size
	EXPECTED=$((EXPECTED+FILES_SIZE[I]))
	SIZE=$(stat --printf="%s" $FILE)
	if [ $SIZE -ne $EXPECTED ]; then
		echo "Error: Chunk $CHUNK_NR inflated size does not match"
		exit 3
	fi
	debug "Debug: Inflated file size $SIZE/$EXPECTED bytes"
done

debug "Debug: Inflated $Z_FILE"