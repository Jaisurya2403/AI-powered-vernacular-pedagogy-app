# Offline AI Model Repository & Setup Guide

This folder holds the offline AI runtime models for **Speech-to-Text (ASR)**, **Neural Machine Translation (NMT)**, and **Text-to-Speech (TTS)** designed for **2GB RAM offline Android devices**.

## 1. Speech-to-Text (ASR) - Hindi & Tribal
- **Recommended Engine**: Vosk Offline ASR (`vosk-model-small-hi-0.22`)
- **Directory**: `assets/models/vosk_hindi/`
- **Download Link**: https://alphacephei.com/vosk/models
- **Usage**: Extract the model folder here. The app will automatically initialize the Vosk C/C++ engine for offline microphone input.

## 2. Text-to-Speech (TTS) - Meta MMS-TTS (Tribal Languages)
- **Recommended Engine**: Meta MMS-TTS INT8 Quantized ONNX (`mms-tts-sat`, `mms-tts-hoc`, `mms-tts-unr`)
- **Directory**: `assets/models/mms_tts/`
- **Download Link**: HuggingFace Meta MMS Repository (ONNX export)
- **Usage**: Place `.onnx` files here. Provides natural voice synthesis for Santhali, Ho, and Mundari.

## 3. Distilled NMT Model (Hindi -> Tribal Fallback)
- **Recommended Engine**: Distilled MarianMT / NMT Quantized Model (`hindi_tribal_nmt_q4.onnx`)
- **Directory**: `assets/models/nmt_distilled/`
- **Usage**: Fallback engine when neither Phrase Bank nor A* Search covers an ultra-rare word.
