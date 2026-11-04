#!/usr/bin/env python3
"""Opt-in HTTPS wire checks. Requires licensed Wolfram 15, curl >=8.4 and OpenSSL.

Uses only loopback servers and a temporary CA passed to an explicit curl wrapper.
Does not install trust, use --insecure, or contact an external data provider.
"""
import argparse
from collections import Counter
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import ssl
import subprocess
import sys
import tempfile
import threading
import time
from urllib.parse import urlsplit

EXACT = b"a" * 1024
LARGE_BYTES = 256 * 1024


def find_curl(explicit):
    candidates = [explicit] if explicit else [str(Path(p) / "curl") for p in os.get_exec_path()]
    for candidate in dict.fromkeys(candidates):
        if not candidate or not os.path.isfile(candidate):
            continue
        try:
            output = subprocess.run([candidate, "--disable", "--version"], capture_output=True,
                                    text=True, timeout=5, check=True).stdout
            match = re.match(r"curl (\d+)\.(\d+)\.(\d+)", output)
            if match and tuple(map(int, match.groups())) >= (8, 4, 0):
                return str(Path(candidate).resolve())
        except (OSError, subprocess.SubprocessError):
            pass
    raise RuntimeError("curl 8.4 or newer was not found; pass --curl /absolute/path")


def create_certificate(directory, openssl):
    def run(*arguments):
        subprocess.run([openssl, *arguments], cwd=directory, check=True,
                       capture_output=True, timeout=30)
    run("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
        "-subj", "/CN=BioDataLink temporary test CA", "-keyout", "ca.key", "-out", "ca.crt")
    run("req", "-newkey", "rsa:2048", "-nodes", "-subj", "/CN=localhost",
        "-keyout", "server.key", "-out", "server.csr")
    (directory / "server.ext").write_text(
        "subjectAltName=DNS:localhost,IP:127.0.0.1\n"
        "extendedKeyUsage=serverAuth\nbasicConstraints=critical,CA:FALSE\n")
    run("x509", "-req", "-in", "server.csr", "-CA", "ca.crt", "-CAkey", "ca.key",
        "-CAcreateserial", "-days", "1", "-extfile", "server.ext", "-out", "server.crt")


def make_handler(events, scheme):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, *_):
            pass

        def do_GET(self):
            path = urlsplit(self.path).path
            events[scheme + " requests"] += 1
            if path == "/slow":
                time.sleep(1)
            try:
                if path in ("/redirect", "/downgrade"):
                    target = self.server.secure_url if path == "/redirect" else self.server.plain_url
                    self.send_response(302)
                    self.send_header("Location", target + "/exact?token=synthetic-redirect-secret")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                large = path in ("/known-large", "/unknown-large")
                payload = b"b" * LARGE_BYTES if large else EXACT
                self.send_response(200)
                if path not in ("/unknown-large", "/unknown-exact"):
                    self.send_header("Content-Length", str(len(payload)))
                self.send_header("Connection", "close")
                self.end_headers()
                for start in range(0, len(payload), 1024):
                    chunk = payload[start:start + 1024]
                    self.wfile.write(chunk)
                    self.wfile.flush()
                    events[path + " bytes sent"] += len(chunk)
                    if large:
                        time.sleep(0.003)
                self.close_connection = True
            except (BrokenPipeError, ConnectionResetError, ssl.SSLError):
                events[path + " client stopped"] += 1
                self.close_connection = True
    return Handler


def wolfram_script(repository, directory, wrapper, slow_version, secure_url):
    # JSON string quoting is used only in a source file, never as shell escaping.
    quote = lambda value: json.dumps(str(value), ensure_ascii=False)
    return f'''
PacletDirectoryLoad[{quote(repository / "BioDataLink")}];
If[Check[Needs["WolframInstitute`BioDataLink`"]; True, False] =!= True, Exit[2]];
output = {quote(directory / "outputs")};
base = {quote(secure_url)};
wrapper = {quote(wrapper)};
results = {{}};
record[name_, condition_] := AppendTo[results, <|"Case" -> name, "Passed" -> TrueQ[condition]|>];
clean[] := FileNames[".biodatalink-*.part", output] === {{}};
run[endpoint_, name_, options___Rule] := BioDatasetDownload[base <> endpoint,
    File[FileNameJoin[{{output, name}}]], options, "CurlExecutable" -> wrapper];

digest = "{hashlib.sha256(EXACT).hexdigest()}";
r = run["/exact", "exact", "MaxFileBytes" -> 1024, "ExpectedByteCount" -> 1024, "ExpectedSHA256" -> digest];
record["Exact limit with Content-Length", AssociationQ[r] && r["ByteCount"] === 1024 && r["Verification"] === "VerifiedSHA256" && clean[]];
r = run["/unknown-exact", "unknown-exact", "MaxFileBytes" -> 1024, "ExpectedSHA256" -> digest];
record["Exact limit without Content-Length", AssociationQ[r] && r["ByteCount"] === 1024 && clean[]];
Do[
    r = run["/" <> name, name, "MaxFileBytes" -> 1024];
    record[name <> " is bounded and cleaned", MatchQ[r, Failure["FileTooLarge", _]] &&
        !FileExistsQ[FileNameJoin[{{output, name}}]] && clean[]],
    {{name, {{"known-large", "unknown-large"}}}}];
r = run["/redirect?token=synthetic-original-secret", "redirect", "MaxFileBytes" -> 1024, "ExpectedSHA256" -> digest];
record["HTTPS redirect and query redaction", AssociationQ[r] && r["RedirectCount"] === 1 &&
    !StringContainsQ[ToString[r, InputForm], "synthetic-"] && clean[]];
r = run["/downgrade", "downgrade", "MaxFileBytes" -> 1024];
record["HTTP redirect refused", FailureQ[r] && !FileExistsQ[FileNameJoin[{{output, "downgrade"}}]] && clean[]];
old = FileNameJoin[{{output, "existing"}}];
Export[old, "previous verified data", "Text"];
r = run["/exact", "existing", "Overwrite" -> True, "MaxFileBytes" -> 1024, "ExpectedSHA256" -> StringRepeat["0", 64]];
record["Checksum failure preserves destination", MatchQ[r, Failure["ChecksumMismatch", _]] && Import[old, "Text"] === "previous verified data" && clean[]];
{{elapsed, r}} = AbsoluteTiming[run["/slow", "slow", "TimeConstraint" -> 0.2, "MaxFileBytes" -> 1024]];
record["Timeout returns promptly and cleans partial file", MatchQ[r, Failure["Timeout", _]] && elapsed < 3 &&
    !FileExistsQ[FileNameJoin[{{output, "slow"}}]] && clean[]];
{{elapsed, r}} = AbsoluteTiming[run["/exact", "version-timeout", "TimeConstraint" -> 0.2,
    "CurlExecutable" -> {quote(slow_version)}]];
record["Time budget includes backend version probe", MatchQ[r, Failure["Timeout", _]] && elapsed < 1.5 &&
    !FileExistsQ[FileNameJoin[{{output, "version-timeout"}}]] && clean[]];
Export[{quote(directory / "results.json")}, results, "RawJSON"];
Print[Length[results], " local TLS cases evaluated."];
Exit[If[AllTrue[results, TrueQ[#["Passed"]] &], 0, 1]];
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--curl", help="Absolute path to curl >=8.4")
    parser.add_argument("--wolframscript", default=os.environ.get("WOLFRAMSCRIPT") or shutil.which("wolframscript"))
    parser.add_argument("--openssl", default=shutil.which("openssl"))
    args = parser.parse_args()
    if os.name != "posix" or not args.wolframscript or not args.openssl:
        parser.error("This opt-in test requires POSIX, openssl and licensed wolframscript")
    curl = find_curl(args.curl)
    repository = Path(__file__).resolve().parents[3]
    events = Counter()
    with tempfile.TemporaryDirectory(prefix="biodatalink-https-") as temporary:
        directory = Path(temporary)
        (directory / "outputs").mkdir()
        create_certificate(directory, args.openssl)
        # --disable must be the first argument so curl never loads a user's .curlrc.
        wrapper = directory / "curl-with-local-ca"
        wrapper.write_text("#!/bin/sh\nexec " + shlex.quote(curl) + " --disable --cacert " +
                           shlex.quote(str(directory / "ca.crt")) + " --noproxy '*' \"$@\"\n")
        wrapper.chmod(0o700)
        slow_version = directory / "slow-curl-version"
        slow_version.write_text(f"#!{sys.executable}\nimport time\ntime.sleep(2)\nprint('curl 8.7.1')\n")
        slow_version.chmod(0o700)
        plain = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(events, "HTTP"))
        secure = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(events, "HTTPS"))
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(directory / "server.crt", directory / "server.key")
        secure.socket = context.wrap_socket(secure.socket, server_side=True)
        secure.secure_url = f"https://127.0.0.1:{secure.server_port}"
        secure.plain_url = f"http://127.0.0.1:{plain.server_port}"
        for server in (plain, secure):
            threading.Thread(target=server.serve_forever, daemon=True).start()
        try:
            script = directory / "checks.wls"
            script.write_text(wolfram_script(repository, directory, wrapper, slow_version, secure.secure_url))
            completed = subprocess.run([args.wolframscript, "-file", str(script)],
                                       capture_output=True, text=True, timeout=60)
            report = directory / "results.json"
            results = json.loads(report.read_text()) if report.exists() else []
            # Let a timed-out handler observe the disconnected client before server shutdown.
            time.sleep(1)
            results.extend([
                {"Case": "No request reached HTTP downgrade target", "Passed": events["HTTP requests"] == 0},
                {"Case": "Unknown-length body was stopped early", "Passed": 0 < events["/unknown-large bytes sent"] < LARGE_BYTES},
            ])
            for result in results:
                print(("PASS " if result["Passed"] else "FAIL ") + result["Case"])
            if completed.returncode or len(results) != 11 or not all(x["Passed"] for x in results):
                print(completed.stdout)
                print(completed.stderr)
                return 1
            print("11 transport checks passed; temporary local trust only.")
            return 0
        finally:
            for server in (secure, plain):
                server.shutdown()
                server.server_close()


if __name__ == "__main__":
    raise SystemExit(main())
