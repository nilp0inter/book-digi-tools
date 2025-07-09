#!/usr/bin/env bash

# Default scanner config
DEVICE=${DEVICE:-"brother5:net1;dev0"}
OUTPUT_PREFIX=${OUTPUT_PREFIX:-"page_"}
OUTPUT_EXT=${OUTPUT_EXT:-"tiff"}
RESOLUTION=${RESOLUTION:-300}
MODE=${MODE:-"True Gray"}
SOURCE=${SOURCE:-"Automatic Document Feeder(center aligned,Duplex)"}
FORMAT=${FORMAT:-"tiff"}

# Optional input: width and height in mm
DOC_WIDTH_MM="${1}"    # e.g. 160
DOC_HEIGHT_MM="${2}"   # e.g. 240

# Flag to determine if we should use AutoDocumentSize or manual geometry
USE_AUTO_SIZE=true
SCAN_GEOMETRY=()

# If both width and height are supplied, calculate geometry and disable AutoDocumentSize
if [[ -n "$DOC_WIDTH_MM" && -n "$DOC_HEIGHT_MM" ]]; then
    USE_AUTO_SIZE=false

    LEFT_OFFSET_MM=$(bc <<< "scale=2; (215.9 - $DOC_WIDTH_MM) / 2")
    TOP_OFFSET_MM=0

    SCAN_GEOMETRY=(-l "${LEFT_OFFSET_MM}" \
                   -t "${TOP_OFFSET_MM}" \
                   -x "${DOC_WIDTH_MM}" \
                   -y "${DOC_HEIGHT_MM}")
fi

# Start page index
START_PAGE=1

# Loop until user exits
while true; do
    # Detect the last scanned page
    if ls ${OUTPUT_PREFIX}*."$OUTPUT_EXT" >/dev/null 2>&1; then
        LAST_PAGE=$(ls ${OUTPUT_PREFIX}*."$OUTPUT_EXT" | sed -E "s/[^0-9]*([0-9]+)\.$OUTPUT_EXT/\1/" | sort -n | tail -n 1)
        START_PAGE=$((LAST_PAGE + 1))
    else
        START_PAGE=1
    fi

    echo "📄 Starting new scan batch from page $START_PAGE..."

    # Build the base scanimage command
    CMD=(scanimage
        -d "$DEVICE"
        --batch="${OUTPUT_PREFIX}%03d.${OUTPUT_EXT}"
        --batch-start="$START_PAGE"
        --format="$FORMAT"
        --resolution="$RESOLUTION"
        --source="$SOURCE"
        --mode="$MODE"
    )

    if $USE_AUTO_SIZE; then
        CMD+=(--AutoDocumentSize=yes)
    else
        CMD+=("${SCAN_GEOMETRY[@]}")
    fi

    # --AutoDeskew can be used in both cases
    CMD+=(--AutoDeskew=yes)

    # Run the scan
    "${CMD[@]}"

    echo ""
    echo "✅ Batch complete."
    read -rp "📥 Refill ADF and press [Enter] for next batch, or Ctrl+C to quit."
    echo ""
done
