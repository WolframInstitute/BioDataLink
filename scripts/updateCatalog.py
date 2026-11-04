#!/usr/bin/env python3
"""Refresh the metadata catalog from an explicit Pertpy commit; never run upstream code."""
import argparse
import ast
import datetime
import hashlib
import json
from pathlib import Path
import re
import urllib.request


def extract(source, revision):
    url = f"https://github.com/scverse/pertpy/blob/{revision}/src/pertpy/data/_datasets.py"
    records = []
    for node in ast.parse(source).body:
        if not isinstance(node, ast.FunctionDef) or node.name.startswith("_"):
            continue
        description = ast.get_docstring(node) or ""
        urls = sorted({
            value.value for call in ast.walk(node)
            if isinstance(call, ast.Call) and isinstance(call.func, ast.Name) and call.func.id == "_download"
            for keyword in call.keywords if keyword.arg == "url"
            for value in [keyword.value]
            if isinstance(value, ast.Constant) and isinstance(value.value, str)
            and value.value.startswith("https://")
        })
        if not urls:
            continue
        summary = description.split("References:")[0].split("Returns:")[0].strip()
        citation = description.split("References:", 1)[-1].split("Returns:")[0].strip() if "References:" in description else None
        records.append({
            "Provider": "Pertpy", "ID": node.name,
            "Title": summary.splitlines()[0] if summary else node.name,
            "Description": " ".join(summary.split()),
            "Organism": None,
            "Citation": " ".join(citation.split()) if citation else None,
            "DocumentationURL": f"https://pertpy.scverse.org/en/stable/api/data/pertpy.data.{node.name}.html",
            "SourceURL": url, "SourceRevision": revision,
            "DownloadURLs": urls, "NativeImportSupported": False,
        })
    if not records or len({r["ID"] for r in records}) != len(records):
        raise ValueError("Expected a nonempty catalog with unique IDs")
    return sorted(records, key=lambda record: record["ID"])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("revision", help="Full 40-character upstream Git commit")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-f0-9]{40}", args.revision):
        parser.error("revision must be a full lowercase Git commit hash")
    base = f"https://raw.githubusercontent.com/scverse/pertpy/{args.revision}/"
    source = urllib.request.urlopen(base + "src/pertpy/data/_datasets.py", timeout=30).read()
    license_text = urllib.request.urlopen(base + "LICENSE", timeout=30).read()
    snapshot = {
        "SchemaVersion": 1,
        "SourceRevision": args.revision,
        "SourceURL": base + "src/pertpy/data/_datasets.py",
        "SourceSHA256": hashlib.sha256(source).hexdigest(),
        "RetrievedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "Records": extract(source.decode("utf-8"), args.revision),
    }
    target = Path(__file__).resolve().parents[1] / "BioDataLink/Assets/Catalog"
    target.mkdir(parents=True, exist_ok=True)
    (target / "pertpy.json").write_text(json.dumps(snapshot, indent=2) + "\n")
    (target / "PERTPY-LICENSE.txt").write_bytes(license_text)
    print(f"Wrote {len(snapshot['Records'])} metadata records from {args.revision}")


if __name__ == "__main__":
    main()
