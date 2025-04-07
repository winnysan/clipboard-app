#!/bin/bash

# Tento skript je potrebné najprv spraviť spustiteľným príkazom:
# chmod +x all-swift-files-to-one-txt.sh

EXTENSION="swift"
SEARCH_PATH="$(pwd)"
TIMESTAMP=$(date +"%d-%m-%y-%H-%M-%S")
OUTPUT_FILE="output-${TIMESTAMP}.txt"

> "$OUTPUT_FILE"
echo "Zbieram .swift súbory v: $SEARCH_PATH"
echo "Ukladám do: $OUTPUT_FILE"

find "$SEARCH_PATH" -type f -iname "*.swift" -print0 |
while IFS= read -r -d '' file; do
  abs_file=$(realpath "$file")
  relative_path="${abs_file#$SEARCH_PATH/}"

  echo "┌──────────────────────────────────────────────────────────────────────────────┐" >> "$OUTPUT_FILE"
  echo "│ Začiatok súboru:  $relative_path" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  cat "$abs_file" >> "$OUTPUT_FILE"

  echo "" >> "$OUTPUT_FILE"
  echo "│ Koniec súboru:  $relative_path" >> "$OUTPUT_FILE"
  echo "└──────────────────────────────────────────────────────────────────────────────┘" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
done

echo "Hotovo. Výstupný súbor: $OUTPUT_FILE"
