import sys
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
import threading

# Inicializace GStreameru proběhne POUZE JEDNOU při startu kontejneru
import gi

gi.require_version('Gst', '1.0')
from gi.repository import Gst, GLib

Gst.init(None)


class IPTVProxyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Dynamické určení kanálu podle cesty v URL (např. /ct1 -> ct1)
        kanal = self.path.strip("/")

        # Ochrana před prázdnou nebo nebezpečnou cestou
        if not kanal or ".." in kanal :
            self.send_error(400, "Neplatny nazev kanalu")
            return

        cesta_k_souboru = f"{kanal}"

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

        # Hlavičky pro standardní MPEG-TS stream
        self.send_response(200)
        self.send_header('Content-Type', 'video/mp2t')
        self.send_header('Connection', 'close')
        self.end_headers()

        print(f"[{kanal}] Startuji stream: {uri}", flush=True)

        # Inicializace seznamu prvků a vyžádaných padů pro pozdější bezpečné uvolnění
        allocated_elements = []
        allocated_request_pads = []

        # Vytvoření lokální pipeline
        pipeline = Gst.Pipeline.new(f"pipeline-{kanal}")
        src = Gst.ElementFactory.make("urisourcebin", None)
        mux = Gst.ElementFactory.make("mpegtsmux", None)
        sink = Gst.ElementFactory.make("fdsink", None)

        src.set_property("uri", uri)
        src.set_property("buffer-duration", 1000000000)  # 1s buffer pro bleskový start
        src.set_property("buffer-size", 1024 * 1024)
        mux.set_property("alignment", -1)

        sink.set_property("fd", self.wfile.fileno())
        sink.set_property("sync", False)
        sink.set_property("async", False)

        pipeline.add(src)
        pipeline.add(mux)
        pipeline.add(sink)
        mux.link(sink)

        def on_pad_added(element, pad):
            caps = pad.get_current_caps()
            if not caps: return
            name = caps.to_string()

            # VIDEO větev
            if "video/x-h265" in name or "video/x-h264" in name:
                q = Gst.ElementFactory.make("queue", None)
                q.set_property("max-size-buffers", 1)
                q.set_property("max-size-time", 0)
                q.set_property("max-size-bytes", 0)
                parser = Gst.ElementFactory.make("h265parse" if "x-h265" in name else "h264parse", None)

                pipeline.add(q)
                pipeline.add(parser)
                allocated_elements.extend([q, parser])

                q.link(parser)
                mux_pad = mux.get_request_pad("sink_%u")
                allocated_request_pads.append(mux_pad)

                parser.get_static_pad("src").link(mux_pad)
                pad.link(q.get_static_pad("sink"))
                q.sync_state_with_parent()
                parser.sync_state_with_parent()

            # AUDIO větev (všechny jazyky dynamicky)
            elif "audio/x-aac" in name:
                q = Gst.ElementFactory.make("queue", None)
                q.set_property("max-size-buffers", 1)
                q.set_property("max-size-time", 0)
                q.set_property("max-size-bytes", 0)
                parser = Gst.ElementFactory.make("aacparse", None)

                pipeline.add(q)
                pipeline.add(parser)
                allocated_elements.extend([q, parser])

                q.link(parser)
                mux_pad = mux.get_request_pad("sink_%u")
                allocated_request_pads.append(mux_pad)

                parser.get_static_pad("src").link(mux_pad)
                pad.link(q.get_static_pad("sink"))
                q.sync_state_with_parent()
                parser.sync_state_with_parent()

            # TITULKY (VTT -> DVBSub)
            elif "text/x-raw" in name or "subtitle" in name or "vtt" in name:
                q = Gst.ElementFactory.make("queue", None)
                q.set_property("max-size-buffers", 2)
                subparse = Gst.ElementFactory.make("subparse", None)
                render = Gst.ElementFactory.make("textrender", None)
                capsfilter = Gst.ElementFactory.make("capsfilter", None)
                encoder = Gst.ElementFactory.make("dvbsubenc", None)

                capsfilter.set_property("caps", Gst.Caps.from_string("video/x-raw,width=1920,height=1080"))

                pipeline.add(q)
                pipeline.add(subparse)
                pipeline.add(render)
                pipeline.add(capsfilter)
                pipeline.add(encoder)
                allocated_elements.extend([q, subparse, render, capsfilter, encoder])

                q.link(subparse)
                subparse.link(render)
                render.link(capsfilter)
                capsfilter.link(encoder)

                mux_pad = mux.get_request_pad("sink_%u")
                allocated_request_pads.append(mux_pad)

                encoder.get_static_pad("src").link(mux_pad)
                pad.link(q.get_static_pad("sink"))

                q.sync_state_with_parent()
                subparse.sync_state_with_parent()
                render.sync_state_with_parent()
                capsfilter.sync_state_with_parent()
                encoder.sync_state_with_parent()

        src.connect("pad-added", on_pad_added)
        pipeline.set_state(Gst.State.PLAYING)

        bus = pipeline.get_bus()
        try:
            while True:
                msg = bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.EOS, 100000000)  # 100ms tick
                if msg:
                    break
        except Exception:
            pass
        finally:
            print(f"[{kanal}] Klient odpojen. Cistim pipeline a uvolnuju RAM...", flush=True)
            pipeline.set_state(Gst.State.NULL)

            # Korektní uvolnění dynamických padů z mpegtsmux (prevence Memory Leaků)
            for pad in allocated_request_pads:
                mux.release_request_pad(pad)

            # Odstranění dynamicky přidaných prvků
            for element in allocated_elements:
                pipeline.remove(element)

            # Odstranění fixních prvků
            pipeline.remove(src)
            pipeline.remove(mux)
            pipeline.remove(sink)


def run_server():
    server = HTTPServer(('0.0.0.0', 8080), IPTVProxyHandler)
    print("IPTV Proxy bezi na portu 8080 a nasloucha na dynamickych URL...", flush=True)
    server.serve_forever()


if __name__ == '__main__':
    loop = GLib.MainLoop()
    t = threading.Thread(target=loop.run)
    t.daemon = True
    t.start()

    run_server()