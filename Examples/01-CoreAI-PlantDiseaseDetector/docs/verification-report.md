# Verification Report

## Commands Actually Run

```bash
cd Examples/01-CoreAI-PlantDiseaseDetector/python
.venv/bin/python --version
.venv/bin/python -c "import torch, ultralytics, yaml; print('imports ok')"
.venv/bin/python validate_environment.py
.venv/bin/python inspect_yolo_model.py --model-path ../models/raw/best.pt --data-yaml configs/full_plant_data.yaml
.venv/bin/python -m pytest tests
.venv/bin/python -m py_compile *.py
find .. -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "../models/*" ! -path "../ios/*/Assets.xcassets/*" | head -20
.venv/bin/python export_yolo_model.py --model-path ../models/raw/best.pt --output-dir ../models/exported --formats torchscript,onnx --imgsz 320
.venv/bin/python convert_to_core_ai.py --model-path ../models/raw/best.pt --output-dir ../models/core-ai --data-yaml configs/full_plant_data.yaml --imgsz 320
.venv/bin/python create_ios_model_package.py --data-yaml configs/full_plant_data.yaml --output-dir ../models/ios-package --core-ai-dir ../models/core-ai
plutil -lint ../ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp/Info.plist
plutil -lint ../ios/PlantDiseaseDetectorApp/PlantDiseaseDetectorApp.xcodeproj/project.pbxproj
```

## Pass / Fail Status

- `.venv` Python version (`Python 3.13.7`): pass
- `torch`, `ultralytics`, and `yaml` imports inside `.venv`: pass
- Local `best.pt` presence check: pass
- `validate_environment.py`: pass
- `inspect_yolo_model.py`: pass
- YAML class count: pass (`38`)
- Model class count: pass (`38`)
- Model/YAML class order match: pass
- `pytest` run for `python/tests`: pass (`11 passed`)
- Python syntax compilation via `.venv/bin/python -m py_compile *.py`: pass
- Local detection: skipped, no reasonable plant or leaf sample image was available in the repository
- `export_yolo_model.py`: pass
- TorchScript export: pass, `models/exported/best.torchscript`
- ONNX export: pass, `models/exported/best.onnx`
- `convert_to_core_ai.py`: pass for blocked-path behavior; wrote `models/core-ai/core_ai_conversion_metadata.json` with status `blocked`
- `.aimodel` generation: blocked
- `create_ios_model_package.py`: pass; wrote `models/ios-package/model_contract.json`, `plant_disease_labels.json`, and `README.md`
- iOS `Info.plist` lint: pass
- iOS `project.pbxproj` lint: pass

## Environment Limitations

- No reasonable local plant/leaf sample image was available, so real one-image detection was not run.
- Core AI conversion remained blocked because no official Core AI Python tooling was discoverable in this environment.
- Generated export/conversion artifacts remain local and ignored; they are not committed to Git.

## Not Verified

- Real one-image detector inference on a local plant/leaf sample
- Real Core AI `.aimodel` generation
- Real Core AI runtime inference inside the iOS app
- Xcode app build success
