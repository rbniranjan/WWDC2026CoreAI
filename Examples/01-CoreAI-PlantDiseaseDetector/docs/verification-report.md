# Verification Report

## Python / Model Verification

Commands run from `Examples/01-CoreAI-PlantDiseaseDetector/python`:

```bash
.venv/bin/python --version
.venv/bin/python -c "import torch, ultralytics, yaml; print('imports ok')"
.venv/bin/python validate_environment.py
.venv/bin/python inspect_yolo_model.py --model-path ../models/raw/best.pt --data-yaml configs/full_plant_data.yaml
.venv/bin/python -m pytest tests
.venv/bin/python -m py_compile *.py
.venv/bin/python export_yolo_model.py --model-path ../models/raw/best.pt --output-dir ../models/exported --formats torchscript,onnx --imgsz 320
.venv-coreai/bin/python --version
.venv-coreai/bin/python -c "import torch, coreai_torch; print(torch.__version__, coreai_torch.__version__)"
MPLCONFIGDIR=/tmp/mpl .venv-coreai/bin/python convert_to_core_ai.py --model-path ../models/raw/best.pt --output-dir ../models/core-ai --data-yaml configs/full_plant_data.yaml --imgsz 320 --overwrite
.venv/bin/python create_ios_model_package.py --data-yaml configs/full_plant_data.yaml --output-dir ../models/ios-package --core-ai-dir ../models/core-ai
```

Verified results:

- `.venv` Python version: `Python 3.13.7`
- `.venv-coreai` Python version: `Python 3.12.13`
- `torch`, `ultralytics`, `yaml` imports: pass
- `torch` + `coreai_torch` imports in `.venv-coreai`: pass
- YAML class count: pass (`38`)
- model class count: pass (`38`)
- YAML / model class order match: pass
- `pytest` run: pass (`11 passed`)
- Python compile check: pass
- TorchScript export: pass
- ONNX export: pass
- Core AI conversion: pass
- Generated local `.aimodel`: `models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`
- Generated local conversion metadata: `models/core-ai/core_ai_conversion_metadata.json`

## iOS Verification

The iOS app was verified with Xcode beta using inline `DEVELOPER_DIR`. The system default Xcode was not changed.

Verified local beta path on the author machine:

```bash
export BETA_DEVELOPER_DIR="/Users/rniranjan/Downloads/Xcode-beta.app/Contents/Developer"
```

Commands run from `Examples/01-CoreAI-PlantDiseaseDetector/ios/PlantDiseaseDetectorApp`:

```bash
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild -version
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcrun swift --version
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild -list
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" swift test --scratch-path /tmp/plant-disease-detector-swiftpm-build
DEVELOPER_DIR="$BETA_DEVELOPER_DIR" xcodebuild \
  -project PlantDiseaseDetectorApp.xcodeproj \
  -scheme PlantDiseaseDetectorApp \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/plant-disease-detector-derived-data \
  build
plutil -lint PlantDiseaseDetectorApp/Info.plist
python3 -m json.tool PlantDiseaseDetectorApp/Resources/ModelContract/model_contract.json
```

Verified results:

- Xcode beta: `Xcode 27.0`
- build version: `27A5194q`
- Swift: `6.4`
- project/scheme discovery: pass
- SwiftPM tests: pass (`4 tests, 0 failures`)
- Xcode build: `BUILD SUCCEEDED`
- `Info.plist` lint: pass
- bundled `model_contract.json` parse: pass

## Model Artifact Policy Verification

Ignore checks verified:

- `models/raw/best.pt`: ignored
- `models/core-ai/FarmerHelper_YOLO26_RawDetector.aimodel`: ignored
- `models/core-ai/core_ai_conversion_metadata.json`: ignored
- `ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Resources/AIModels/FarmerHelper_YOLO26_RawDetector.aimodel`: ignored

## What Is Verified

- YOLO class contract validation
- Core AI raw detector conversion
- local-only model sync workflow
- Swift raw-output postprocessing foundation
- class-aware NMS tests
- Xcode beta simulator build

## What Is Not Verified

- Real plant-image inference sample committed to the repository
- Final production Core AI runtime API wiring in the app
- Distribution of model artifacts through Git
