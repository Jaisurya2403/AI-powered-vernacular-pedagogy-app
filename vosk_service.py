import os
import json
import queue
import threading
import wave
import io
from http.server import HTTPServer, BaseHTTPRequestHandler
import vosk

# 1. Initialize Vosk Hindi Model
MODEL_NAME = "vosk-model-small-hi-0.22"
print(f"[VoskService] Loading model '{MODEL_NAME}'...")
try:
    model = vosk.Model(model_name=MODEL_NAME)
    print(f"[VoskService] Vosk model '{MODEL_NAME}' loaded successfully!")
except Exception as e:
    print(f"[VoskService] Model init error: {e}")
    # Fallback to cache directory if model_name auto-fetch is cached
    cache_path = os.path.expanduser(f"~/.cache/vosk/{MODEL_NAME}")
    if os.path.exists(cache_path):
        model = vosk.Model(cache_path)
        print(f"[VoskService] Loaded model from cache path: {cache_path}")
    else:
        raise e

recognizer = vosk.KaldiRecognizer(model, 16000)
recognizer.SetWords(True)

# 2. Continuous Thread-Safe Audio Queue Buffer
audio_queue = queue.Queue()
recognized_sentences = []
lock = threading.Lock()

def audio_processing_worker():
    """Worker thread that continuously consumes audio chunks from queue without losing words."""
    while True:
        try:
            chunk = audio_queue.get(timeout=1.0)
            if chunk is None:
                continue
            
            if recognizer.AcceptWaveform(chunk):
                res = json.loads(recognizer.Result())
                text = res.get("text", "").strip()
                if text:
                    with lock:
                        recognized_sentences.append(text)
                        print(f"[Vosk Engine Recognized]: {text}")
            else:
                partial_res = json.loads(recognizer.PartialResult())
                partial_text = partial_res.get("partial", "").strip()
                if partial_text:
                    pass
        except queue.Empty:
            continue
        except Exception as e:
            print(f"[Vosk Worker Error]: {e}")

# Start worker thread
worker_thread = threading.Thread(target=audio_processing_worker, daemon=True)
worker_thread.start()

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
                "queue_size": audio_queue.qsize(),
                "total_sentences": len(recognized_sentences)
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

        if self.path == '/api/vosk/push-chunk':
            # Accepts binary audio chunk (PCM 16kHz 16-bit mono) or JSON wrapper
            try:
                if self.headers.get('Content-Type', '').startswith('application/json'):
                    body = json.loads(post_data.decode('utf-8'))
                    text_input = body.get('text', '').strip()
                    if text_input:
                        with lock:
                            recognized_sentences.append(text_input)
                        print(f"[Vosk Text Direct Ingest]: {text_input}")
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
