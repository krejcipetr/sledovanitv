import sys
import os
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading

import gi

gi.require_version("GLib", "2.0")
# noinspection PyUnresolvedReferences
from gi.repository import GLib

import streamlink

class IPTVProxyHandler(BaseHTTPRequestHandler):
    config_directory = None

    def do_GET(self):
        # Dynamické určení kanálu podle cesty v URL (např. /ct1 -> ct1)
        kanal = self.path.strip("/")

        # Ochrana před prázdnou nebo nebezpečnou cestou
        if not kanal or ".." in kanal :
            self.send_error(400, "Neplatny nazev kanalu")
            return

        cesta_k_souboru = os.path.join(self.config_directory, kanal)

        # Načtení aktuální URL ze specifického souboru kanálu
        try:
            with open(cesta_k_souboru, 'r') as f:
                uri = f.read().strip()
        except FileNotFoundError:
            self.send_error(404, f"Kanal '{kanal}' nebyl nalezen (soubor neexistuje)")
            return
        except Exception as e:
            self.send_error(500, f"Chyba pri cteni souboru kanalu: {e}")
            return

        print(f"[{kanal}] Startuji stream: {uri}", flush=True)

        # Streamlink najde dostupné varianty a vybere nejvyšší kvalitu.
        try:
            streams = streamlink.streams(uri)
            stream = streams.get('best')
            if stream is None:
                self.send_error(404, f"Pro kanal '{kanal}' nebyl nalezen zadny stream")
                return

            stream_fd = stream.open()
        except Exception as e:
            print(f"[{kanal}] Streamlink chyba: {e}", flush=True)
            self.send_error(502, f"Stream se nepodarilo otevrit: {e}")
            return

        # Hlavičky pro streamovaná data. Délka není známá, proto se posílá
        # průběžně bez Content-Length.
        self.send_response(200)
        self.send_header('Content-Type', 'video/mp2t')
        self.send_header('Connection', 'close')
        self.end_headers()

        try:
            while True:
                data = stream_fd.read(64 * 1024)
                if not data:
                    break
                self.wfile.write(data)
                self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            # Klient přehrávání ukončil; není to chyba serveru.
            print(f"[{kanal}] Klient ukoncil spojeni", flush=True)
        except Exception as e:
            print(f"[{kanal}] Chyba pri prenosu: {e}", flush=True)
        finally:
            stream_fd.close()
            print(f"[{kanal}] Stream ukoncen", flush=True)

def run_server(port):
    # Každý požadavek zpracuje vlastní vlákno, takže jeden dlouho běžící
    # stream nezablokuje ostatní kanály/klienty.
    server = ThreadingHTTPServer(('127.0.0.1', port), IPTVProxyHandler)
    print(f"IPTV Proxy bezi na portu {port} a nasloucha na dynamickych URL...", flush=True)
    server.serve_forever()


if __name__ == '__main__':
    config_path = os.path.expanduser("~/sledovanitv_config.json")
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        cachedir = config.get("cachedir", "~/.cache/sledovanitv")
        port = config.get("ipvproxy", {}).get("port", 9393)
        if not isinstance(cachedir, str) or not cachedir.strip():
            raise ValueError("hodnota 'cachedir' musi byt neprazdny retezec")
    except (OSError, json.JSONDecodeError, KeyError, ValueError) as e:
        print(f"Chyba pri nacitani konfigurace '{config_path}': {e}", file=sys.stderr)
        sys.exit(1)

    IPTVProxyHandler.config_directory = os.path.expanduser(cachedir)

    loop = GLib.MainLoop()
    t = threading.Thread(target=loop.run)
    t.daemon = True
    t.start()

    run_server(port)
