#!/usr/bin/env python3
"""Serve a pass/fail checklist on the LAN and append results to a JSONL file."""
import argparse, json, secrets, socket, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("scenarios", help='JSON: {"title","device","scenarios":[{"id","title","steps":[]}]}')
    ap.add_argument("--out", default="results.jsonl", help="JSONL file to append results to")
    ap.add_argument("--port", type=int, default=0, help="0 picks a free port")
    ap.add_argument("--host", default="0.0.0.0")
    a = ap.parse_args()
    spec = json.loads(Path(a.scenarios).read_text())
    page = (HERE / "page.html").read_bytes()
    out = Path(a.out)
    token = secrets.token_urlsafe(16)

    class H(BaseHTTPRequestHandler):
        def send(self, code, body, ctype="application/json"):
            self.send_response(code)
            self.send_header("content-type", ctype)
            self.send_header("content-length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def route(self):
            """Path under the token prefix, or None (reply 403) when it is missing."""
            p = self.path.split("?")[0]
            prefix = f"/{token}/"
            if not p.startswith(prefix):
                self.send(403, b'{"error":"forbidden"}')
                return None
            return "/" + p[len(prefix):]

        def do_GET(self):
            p = self.route()
            if p is None:
                return
            if p == "/":
                self.send(200, page, "text/html; charset=utf-8")
            elif p == "/scenarios.json":
                self.send(200, json.dumps(spec).encode())
            else:
                self.send(404, b"{}")

        def do_POST(self):
            p = self.route()
            if p is None:
                return
            if p != "/result":
                return self.send(404, b"{}")
            if self.headers.get("content-type", "").split(";")[0].strip().lower() != "application/json":
                return self.send(415, b'{"error":"content-type must be application/json"}')
            try:
                n = int(self.headers.get("content-length", 0))
                r = json.loads(self.rfile.read(n))
                assert isinstance(r, dict) and r.get("status") in ("pass", "fail", "skip")
            except (ValueError, AssertionError):
                return self.send(400, b'{"error":"need json with status pass|fail|skip"}')
            r["ts"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
            r["device"] = spec.get("device")
            with out.open("a") as f:
                f.write(json.dumps(r) + "\n")
            self.send(200, b'{"ok":true}')

        def log_message(self, *args):
            pass

    srv = ThreadingHTTPServer((a.host, a.port), H)
    print(f"http://{lan_ip()}:{srv.server_port}/{token}/  results -> {out}", flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)


if __name__ == "__main__":
    main()
