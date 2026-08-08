import sys
import os
import json
import time
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from streamlink import Streamlink

class IPTVProxyHandler(BaseHTTPRequestHandler):
    config_directory = None

    def __init__(self, *args, **kwargs):
        self.transferred_bytes = 0
        self.last_log_time = None
        self.log_timer = None
        super().__init__(*args, **kwargs)

    def log_message(self, format, *args):
        # Suppress HTTP request logging
        pass

    def do_GET(self):
        # Dynamické určení kanálu podle cesty v URL (např. /ct1 -> ct1)
        request_start_time = time.time()
        kanal = self.path.strip("/")

        # Ochrana před prázdnou nebo nebezpečnou cestou
        if not kanal or ".." in kanal :
            self.send_error(400, "Neplatny nazev kanalu")
            return

        cesta_k_souboru = os.path.join(self.config_directory, kanal)

        # Načtení aktuální URL ze specifického souboru kanálu
        try:
            with open(cesta_k_souboru, 'r') as f:
                uri =  f.read().strip()

        except FileNotFoundError:
            self.send_error(404, f"Kanal '{kanal}' nebyl nalezen (soubor '{cesta_k_souboru}' neexistuje)")
            return
        except Exception as e:
            self.send_error(500, f"Chyba pri cteni souboru kanalu: {e}")
            return

        print(f"[{kanal}] Stream: {uri}", flush=True)

        # Streamlink najde dostupné varianty a vybere nejvyšší kvalitu.
        try:
            session = Streamlink()
            session.set_option("mux-subtitles", True)
            session.set_option("hls-live-edge", 2)
            session.set_option("hls-segment-ignore-redirect", True)
            session.set_option("stream-segment-threads", 3)

            streams = session.streams(uri)
            stream = streams.get('best')
            if stream is None:
                self.send_error(404, f"Pro kanal '{kanal}' nebyl nalezen zadny stream")
                return

            stream_fd = stream.open()
        except Exception as e:
            print(f"[{kanal}] Streamlink error: {e}", flush=True)
            self.send_error(502, f"Stream se nepodarilo otevrit: {e}")
            return

        # Hlavičky pro streamovaná data. Délka není známá, proto se posílá
        # průběžně bez Content-Length.
        self.send_response(200)
        self.send_header('Content-Type', 'video/mp2t')
        self.send_header('Connection', 'close')
        self.end_headers()

        def log_transfer_stats():
            if self.last_log_time is not None:
                transferred_mb = self.transferred_bytes / (1024 * 1024)
                stream_duration = time.time() - request_start_time
                print(f"[{kanal}] Transferred: {transferred_mb:.2f} MB, Duration: {stream_duration:.1f}s", flush=True)
            self.last_log_time = time.time()
            self.log_timer = threading.Timer(60.0, log_transfer_stats)
            self.log_timer.daemon = True
            self.log_timer.start()

        try:
            first_data_sent = False
            buffersize = 256 * 1024
            while True:
                data = stream_fd.read(buffersize)
                if not data:
                    break
                self.wfile.write(data)
                self.wfile.flush()
                self.transferred_bytes += len(data)
                if not first_data_sent:
                    first_data_time = time.time()
                    elapsed_time = first_data_time - request_start_time
                    print(f"[{kanal}] First data in {elapsed_time:.3f}s", flush=True)
                    first_data_sent = True
                    self.transferred_bytes = 0
                    self.last_log_time = time.time()
                    log_transfer_stats()
        except (BrokenPipeError, ConnectionResetError):
            # Klient přehrávání ukončil; není to chyba serveru.
            print(f"[{kanal}] Connection closed", flush=True)
        except Exception as e:
            print(f"[{kanal}] Chyba pri prenosu: {e}", flush=True)
        finally:
            if self.log_timer is not None:
                self.log_timer.cancel()
            if self.transferred_bytes > 0:
                transferred_mb = self.transferred_bytes / (1024 * 1024)
                stream_duration = time.time() - request_start_time
                print(f"[{kanal}] Total transferred: {transferred_mb:.2f} MB, Duration: {stream_duration:.1f}s",
                      flush=True)
            stream_fd.close()
            print(f"[{kanal}] Streamlink close", flush=True)

def run_server(port):
    server = ThreadingHTTPServer(('127.0.0.1', port), IPTVProxyHandler)
    print(f"IPTV Proxy on 127.0.0.1:{port} streams in {IPTVProxyHandler.config_directory}", flush=True)
    server.serve_forever()


if __name__ == '__main__':
    if len(sys.argv) > 1:
        config_path = os.path.expanduser(sys.argv[1])
    else:
        config_path = os.path.expanduser("~/sledovanitv-config.json")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        cachedir = config.get("tempdir", "~/.cache")
        cachedir = os.path.expanduser(os.path.join(cachedir, "sledovanitv"))
        port = config.get("ipvproxy", {}).get("port", 9393)
        if not isinstance(cachedir, str) or not cachedir.strip():
            raise ValueError("hodnota 'cachedir' musi byt neprazdny retezec")
    except (OSError, json.JSONDecodeError, KeyError, ValueError) as e:
        print(f"Chyba pri nacitani konfigurace '{config_path}': {e}", file=sys.stderr)
        sys.exit(1)

    IPTVProxyHandler.config_directory = os.path.expanduser(cachedir)

    run_server(port)
