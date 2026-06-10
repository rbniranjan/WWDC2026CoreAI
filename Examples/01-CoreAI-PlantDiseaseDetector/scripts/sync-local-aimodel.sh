#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EXAMPLE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SOURCE_MODEL="$EXAMPLE_DIR/models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel"
DESTINATION_DIR="$EXAMPLE_DIR/ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels"
DESTINATION_MODEL="$DESTINATION_DIR/FarmerHelper_YOLO26_RawDetector.aimodel"

if [ ! -d "$SOURCE_MODEL" ]; then
    echo "ERROR: source .aimodel is missing."
    echo "Expected source: $SOURCE_MODEL"
    echo "Generate it locally with convert_to_core_ai.py before syncing."
    exit 1
fi

mkdir -p "$DESTINATION_DIR"
rm -rf "$DESTINATION_MODEL"
cp -R "$SOURCE_MODEL" "$DESTINATION_MODEL"

echo "Copied local .aimodel for app testing."
echo "Source: $SOURCE_MODEL"
echo "Destination: $DESTINATION_MODEL"
echo "Note: destination remains ignored and local-only."
