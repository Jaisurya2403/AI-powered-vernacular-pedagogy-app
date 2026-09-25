import os
import json
import queue
import threading
import wave
import io
import numpy as np
from http.server import HTTPServer, BaseHTTPRequestHandler
import vosk

# Try sounddevice for direct hardware microphone input stream
try:
    import sounddevice as sd
    HAS_SOUNDDEVICE = True
except Exception:
    HAS_SOUNDDEVICE = False

# 1. Initialize Vosk Hindi Model
MODEL_NAME = "vosk-model-small-hi-0.22"
print(f"[VoskService] Loading model '{MODEL_NAME}'...")
try:
    model = vosk.Model(model_name=MODEL_NAME)
    print(f"[VoskService] Vosk model '{MODEL_NAME}' loaded successfully!")
except Exception as e:
    print(f"[VoskService] Model init error: {e}")
    cache_path = os.path.expanduser(f"~/.cache/vosk/{MODEL_NAME}")
    if os.path.exists(cache_path):
        model = vosk.Model(cache_path)
        print(f"[VoskService] Loaded model from cache path: {cache_path}")
    else:
        raise e

recognizer = vosk.KaldiRecognizer(model, 16000)
recognizer.SetWords(True)

# 2. Audio Queue & VAD State
audio_queue = queue.Queue()
recognized_sentences = []
latest_partial = ""
mic_recording_active = True
lock = threading.Lock()

# RMS Energy Threshold for Voice Activity Detection (VAD)
# Sensitive voice capture: accepts spoken speech above 120 RMS while rejecting silent room hum
RMS_VAD_THRESHOLD = 120.0

def calculate_rms(audio_bytes: bytes) -> float:
    if not audio_bytes:
        return 0.0
    try:
        audio_data = np.frombuffer(audio_bytes, dtype=np.int16)
        if len(audio_data) == 0:
            return 0.0
        return float(np.sqrt(np.mean(audio_data.astype(np.float64)**2)))
    except Exception:
        return 0.0

def audio_processing_worker():
    """Worker thread that continuously consumes audio chunks from queue and runs Vosk recognition."""
    global latest_partial
    while True:
        try:
            chunk = audio_queue.get(timeout=1.0)
            if chunk is None:
                continue

            if not mic_recording_active:
                continue

            # Voice Activity Detection (VAD) check
            rms_val = calculate_rms(chunk)
            if rms_val < RMS_VAD_THRESHOLD:
                # Ambient noise / room hum -> skip chunk
                continue

            if recognizer.AcceptWaveform(chunk):
                res = json.loads(recognizer.Result())
                text = res.get("text", "").strip()
                if text and len(text) > 1:
                    with lock:
                        # Deduplicate back-to-back noise duplicates
                        if not recognized_sentences or recognized_sentences[-1] != text:
                            recognized_sentences.append(text)
                            latest_partial = ""
                            print(f"[Vosk VAD Speech Recognized (RMS: {rms_val:.1f})]: '{text}'")
            else:
                partial_res = json.loads(recognizer.PartialResult())
                ptext = partial_res.get("partial", "").strip()
                if ptext:
                    with lock:
                        latest_partial = ptext
        except queue.Empty:
            continue
        except Exception as e:
            print(f"[Vosk Worker Error]: {e}")

# Start worker thread
worker_thread = threading.Thread(target=audio_processing_worker, daemon=True)
worker_thread.start()

# 3. Direct Hardware Microphone InputStream Thread using Sounddevice
def hardware_mic_listener():
    """Captures continuous 16kHz 16-bit mono audio straight from default hardware microphone."""
    if not HAS_SOUNDDEVICE:
        print("[Vosk Mic Stream]: sounddevice not installed. Mic stream disabled.")
        return

    print("[Vosk Mic Stream]: Starting direct hardware microphone recording stream (16kHz 16-bit Mono)...")

    def mic_callback(indata, frames, time_info, status):
        if status:
            pass
        if mic_recording_active:
            audio_bytes = bytes(indata)
            audio_queue.put(audio_bytes)

    try:
        with sd.RawInputStream(samplerate=16000, blocksize=4000, dtype='int16', channels=1, callback=mic_callback):
            print("[Vosk Mic Stream]: Hardware microphone active & streaming continuously!")
            while True:
                sd.sleep(1000)
    except Exception as mic_err:
        print(f"[Vosk Mic Stream Error]: {mic_err}")

# Start direct hardware mic recording thread
if HAS_SOUNDDEVICE:
    mic_thread = threading.Thread(target=hardware_mic_listener, daemon=True)
    mic_thread.start()

class VoskHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == '/api/vosk/status':
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            resp = {
                "status": "online",
                "model": MODEL_NAME,
                "hardware_mic_active": HAS_SOUNDDEVICE and mic_recording_active,
                "queue_size": audio_queue.qsize(),
                "total_sentences": len(recognized_sentences)
            }
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        elif self.path.startswith('/api/vosk/poll-new'):
            # Parse 'since' query parameter
            since_idx = 0
            if 'since=' in self.path:
                try:
                    since_idx = int(self.path.split('since=')[1].split('&')[0])
                except Exception:
                    since_idx = 0

            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()

            with lock:
                new_sentences = recognized_sentences[since_idx:] if since_idx < len(recognized_sentences) else []
                total_cnt = len(recognized_sentences)
                ptext = latest_partial

            resp = {
                "new_sentences": new_sentences,
                "next_index": total_cnt,
                "partial": ptext,
                "total_sentences": total_cnt
            }
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        elif self.path == '/api/vosk/results':
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            with lock:
                resp = {"sentences": list(recognized_sentences)}
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length > 0 else b''

        if self.path == '/api/vosk/mic/mute':
            global mic_recording_active
            mic_recording_active = False
            with audio_queue.mutex:
                audio_queue.queue.clear()
            print("[Vosk Mic Muted]: Microphone ingestion paused during TTS playback.")
            self.send_response(200)
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "muted": True}).encode('utf-8'))
            return
        elif self.path == '/api/vosk/mic/unmute':
            mic_recording_active = True
            with lock:
                latest_partial = ""
                try:
                    recognizer.Reset()
                except Exception:
                    pass
            print("[Vosk Mic Unmuted]: Microphone ingestion resumed with fresh acoustic buffer.")
            self.send_response(200)
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "muted": False}).encode('utf-8'))
            return
        elif self.path == '/api/vosk/push-chunk':
            try:
                if self.headers.get('Content-Type', '').startswith('application/json'):
                    body = json.loads(post_data.decode('utf-8'))
                    text_input = (body.get('text') or body.get('chunk') or '').strip()
                    if text_input:
                        with lock:
                            recognized_sentences.append(text_input)
                        print(f"[Vosk Text Direct Ingest]: '{text_input}'")
                        self.send_response(200)
                        self._send_cors_headers()
                        self.send_header('Content-Type', 'application/json')
                        self.end_headers()
                        self.wfile.write(json.dumps({"success": True, "text": text_input}).encode('utf-8'))
                        return
                else:
                    audio_queue.put(post_data)
                    self.send_response(200)
                    self._send_cors_headers()
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({"success": True, "queue_size": audio_queue.qsize()}).encode('utf-8'))
                    return
            except Exception as e:
                self.send_response(500)
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
                return
        else:
            self.send_response(404)
            self.end_headers()

def run_vosk_server():
    server_address = ('', 8086)
    httpd = HTTPServer(server_address, VoskHandler)
    print("Vosk Hindi STT Microservice listening on http://127.0.0.1:8086 ...")
    httpd.serve_forever()

if __name__ == '__main__':
    run_vosk_server()
