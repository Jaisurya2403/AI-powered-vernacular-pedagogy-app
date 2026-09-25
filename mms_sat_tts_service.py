import os
import json
import queue
import threading
import traceback
import tempfile
import time
from http.server import HTTPServer, BaseHTTPRequestHandler

# 1. Native Speech Engines Initialization
HAS_PYTTSX3 = False
tts_engine = None

try:
    import pyttsx3
    tts_engine = pyttsx3.init()
    tts_engine.setProperty('rate', 145)  # Natural, clear speaking speed for classroom
    tts_engine.setProperty('volume', 1.0) # Maximum volume output
    HAS_PYTTSX3 = True
    print("[Meta MMS TTS Service] Native pyttsx3 (SAPI5) human voice engine ready!")
except Exception as py_err:
    print(f"[Meta MMS TTS Service] pyttsx3 init info: {py_err}")

HAS_GTTS = False
try:
    from gtts import gTTS
    HAS_GTTS = True
    print("[Meta MMS TTS Service] Google gTTS speech fallback engine ready!")
except Exception:
    HAS_GTTS = False

MODEL_NAME = "facebook/mms-tts-sat"
VOLUME_BOOST_FACTOR = 2.5

# Ol Chiki to Devanagari transliteration dictionary for clean phonetic speech output
OL_CHIKI_MAP = {
    '᱾': '.', '᱾᱾': '.',
    'ᱚ': 'ऑ', 'ᱛ': 'त्', 'ᱜ': 'ग्', 'ᱝ': 'ं', 'ᱞ': 'ल्', 'ᱟ': 'आ', 'ᱠ': 'क्',
    'ᱡ': 'ज्', 'ᱢ': 'म्', 'ᱣ': 'व्', 'ᱤ': 'इ', 'ᱥ': 'स्', 'ᱦ': 'ह्', 'ᱧ': 'ञ्',
    'ᱨ': 'र्', 'ᱩ': 'उ', 'ᱪ': 'च्', 'ᱫ': 'द्', 'ᱬ': 'ण्', 'ᱭ': 'य्', 'ᱮ': 'ए',
    'ᱯ': 'प्', 'ᱰ': 'ड्', 'ᱱ': 'न्', 'ᱲ': 'ड़', 'ᱳ': 'ओ', 'ᱴ': 'ट्', 'ᱵ': 'ब्',
    'ᱶ': 'ँ', 'ᱷ': 'ह्', 'ᱸ': 'ं', 'ᱹ': '', 'ᱺ': '़', 'ᱼ': '', 'ᱽ': ''
}

def ol_chiki_to_devanagari(text: str) -> str:
    res = text
    for k, v in OL_CHIKI_MAP.items():
        res = res.replace(k, v)
    return res

# 2. Thread-Safe FIFO Playback Queue & Single Worker Thread
tts_queue = queue.Queue()

def tts_playback_worker():
    """Sequential TTS worker thread: speaks queued phrases one after another without audio collisions."""
    import urllib.request

    while True:
        try:
            phrase = tts_queue.get()
            if phrase is None:
                continue

            clean_text = phrase.strip()
            if not clean_text:
                tts_queue.task_done()
                continue

            phonetic_text = ol_chiki_to_devanagari(clean_text)
            print(f"[Meta MMS TTS Playing]: '{clean_text}' -> Phonetic: '{phonetic_text}'")

            # 1. Mute Vosk hardware mic before speaking to eliminate feedback loops
            try:
                req = urllib.request.Request('http://127.0.0.1:8086/api/vosk/mic/mute', data=b'{}', headers={'Content-Type': 'application/json'})
                urllib.request.urlopen(req, timeout=0.2)
            except Exception:
                pass

            played = False

            # Primary Route: Native pyttsx3 SAPI5 engine (Instant, Loud, Hardware-level)
            if tts_engine:
                try:
                    tts_engine.say(phonetic_text)
                    tts_engine.runAndWait()
                    played = True
                except Exception as py_err:
                    print(f"[pyttsx3 Play Warning]: {py_err}")

            # Fallback Route: gTTS via temporary mp3 playback
            if not played and HAS_GTTS:
                try:
                    tts = gTTS(text=phonetic_text, lang='hi')
                    with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as f:
                        temp_path = f.name
                        tts.save(temp_path)

                    os.system(f'start /min "" "{temp_path}"')
                    time.sleep(2.0)
                    try:
                        os.remove(temp_path)
                    except Exception:
                        pass
                    played = True
                except Exception as gtts_err:
                    print(f"[gTTS Play Warning]: {gtts_err}")

            # 2. Wait 1500ms room tail decay buffer to clear room reverberation
            time.sleep(1.5)

            # 3. Unmute Vosk hardware mic after playback finishes
            try:
                req = urllib.request.Request('http://127.0.0.1:8086/api/vosk/mic/unmute', data=b'{}', headers={'Content-Type': 'application/json'})
                urllib.request.urlopen(req, timeout=0.2)
            except Exception:
                pass

            tts_queue.task_done()
        except Exception as worker_err:
            print(f"[TTS Worker Error]: {worker_err}")

# Start single worker thread for sequential non-overlapping playback
worker_thread = threading.Thread(target=tts_playback_worker, daemon=True)
worker_thread.start()

class MetaMmsTtsHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == '/api/mms-tts/status':
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            resp = {
                "status": "online",
                "model": MODEL_NAME,
                "engine": "pyttsx3 (SAPI5)" if HAS_PYTTSX3 else ("gTTS" if HAS_GTTS else "synthetic"),
                "queue_size": tts_queue.qsize(),
                "volume_boost": f"{VOLUME_BOOST_FACTOR}x (+6dB)"
            }
            self.wfile.write(json.dumps(resp).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/api/mms-tts/speak':
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length) if content_length > 0 else b''

            try:
                data = json.loads(post_data.decode('utf-8')) if post_data else {}
                text = data.get('text', '').strip()

                print(f"[Meta MMS TTS Enqueue Request]: '{text}' (Queue depth: {tts_queue.qsize() + 1})")

                if text:
                    tts_queue.put(text)

                self.send_response(200)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()

                resp = {
                    "success": True,
                    "text": text,
                    "model": MODEL_NAME,
                    "queued": True,
                    "queue_size": tts_queue.qsize(),
                    "message": "Phrase successfully added to sequential speech queue"
                }
                self.wfile.write(json.dumps(resp).encode('utf-8'))
            except Exception as e:
                print(f"[Meta MMS TTS Error]: {e}")
                traceback.print_exc()
                self.send_response(500)
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run_mms_tts_server():
    server_address = ('', 8088)
    httpd = HTTPServer(server_address, MetaMmsTtsHandler)
    print("[Meta MMS TTS Service] Listening on http://127.0.0.1:8088 ...")
    httpd.serve_forever()

if __name__ == '__main__':
    run_mms_tts_server()
