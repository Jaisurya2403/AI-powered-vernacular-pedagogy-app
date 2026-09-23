# Sherpa-ONNX Streaming Hindi ASR Model Directory

This directory holds the Zipformer / Transducer ONNX model files for **Offline Streaming Hindi Speech-to-Text**.

## Required Model Files:
1. `encoder.onnx` (or `encoder-epoch-99-avg-1.onnx` / `encoder.int8.onnx`)
2. `decoder.onnx` (or `decoder.int8.onnx`)
3. `joiner.onnx` (or `joiner.int8.onnx`)
4. `tokens.txt`

## Recommended Model Download:
Download `sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20` or `sherpa-onnx-streaming-zipformer-hindi-2024` from:
https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models

Extract the four files directly into this directory (`assets/models/sherpa_hindi/`).
On first launch, the app will extract these files to device storage using `path_provider` to allow native C++ ONNX Runtime file access.
