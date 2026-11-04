#!/usr/bin/env python3
"""Refresh the complete Identifiers.org source registry; retrieve metadata only."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.request

SOURCE_URL = "https://registry.api.identifiers.org/resolutionApi/getResolverDataset"
MAX_BYTES = 4 * 1024 * 1024
TIMEOUT = 30
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "BioDataLink/Assets/Sources/identifiers.json"


def fetch_source():
    request = urllib.request.Request(SOURCE_URL, headers={
        "Accept": "application/json", "User-Agent": "BioDataLink-source-registry/0.2"
    })
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        source = response.read(MAX_BYTES + 1)
    if len(source) > MAX_BYTES:
        raise ValueError("Identifiers.org metadata exceeds the 4 MiB retrieval limit")
    return source


def validate_record(record, identities, strings, flags):
    if not isinstance(record, dict):
        raise ValueError("Expected a registry record object")
    identity = record.get("id")
    if type(identity) is not int or identity <= 0 or identity in identities:
        raise ValueError("Registry IDs must be unique positive integers")
    identities.add(identity)
    if any(not isinstance(record.get(key), str) for key in strings):
        raise ValueError("Missing or invalid registry text field")
    if any(type(record.get(key)) is not bool for key in flags):
        raise ValueError("Missing or invalid registry status flag")


def build_snapshot(source, retrieved_at=None):
    if len(source) > MAX_BYTES:
        raise ValueError("Identifiers.org metadata exceeds the 4 MiB retrieval limit")
    document = json.loads(source)
    if (not isinstance(document, dict) or document.get("apiVersion") != "1.0"
            or "errorMessage" not in document or document["errorMessage"] is not None):
        raise ValueError("Expected a successful Identifiers.org API 1.0 response")
    payload = document.get("payload")
    records = payload.get("namespaces") if isinstance(payload, dict) else None
    if not isinstance(records, list) or not records:
        raise ValueError("Expected a nonempty namespace registry")
    prefixes, namespace_ids, resource_ids = set(), set(), set()
    counts = {"Namespaces": len(records), "Resources": 0, "DeprecatedNamespaces": 0,
              "DeprecatedResources": 0, "ProtectedResources": 0}
    for namespace in records:
        validate_record(namespace, namespace_ids,
                        ("prefix", "name", "description", "pattern", "sampleId"),
                        ("deprecated", "namespaceEmbeddedInLui", "renderDeprecatedLanding"))
        prefix = namespace["prefix"]
        if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", prefix) or prefix in prefixes:
            raise ValueError("Namespace prefixes must be unique lowercase registry identifiers")
        prefixes.add(prefix)
        resources = namespace.get("resources")
        if not isinstance(resources, list):
            raise ValueError("Expected a resource list for each namespace")
        counts["DeprecatedNamespaces"] += namespace["deprecated"]
        counts["Resources"] += len(resources)
        for resource in resources:
            validate_record(resource, resource_ids,
                            ("name", "description", "providerCode", "urlPattern", "sampleId", "resourceHomeUrl"),
                            ("deprecated", "protectedUrls", "official", "renderDeprecatedLanding", "renderProtectedLanding"))
            counts["DeprecatedResources"] += resource["deprecated"]
            counts["ProtectedResources"] += resource["protectedUrls"]
    return {
        "SchemaVersion": 1,
        "Provider": "Identifiers.org",
        "ProviderAPIVersion": document["apiVersion"],
        "SourceURL": SOURCE_URL,
        "SourceSHA256": hashlib.sha256(source).hexdigest(),
        "RetrievedAt": retrieved_at or datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "License": "CC-BY-4.0",
        "LicenseURL": "https://creativecommons.org/licenses/by/4.0/",
        "Attribution": "Identifiers.org registry, provided by the Identifiers.org team at EMBL-EBI.",
        "TermsURL": "https://docs.identifiers.org/pages/terms_of_use.html",
        "Transformations": "Preserved complete namespace records and nested resources; sorted namespaces by prefix and added BioDataLink provenance and counts. No provider URLs were visited.",
        "Counts": counts,
        "Records": sorted(records, key=lambda record: record["prefix"]),
    }


def write_snapshot(target, snapshot):
    target = Path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent,
                                         prefix=".identifiers-", suffix=".tmp", delete=False) as output:
            temporary = Path(output.name)
            json.dump(snapshot, output, ensure_ascii=False, indent=2)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    snapshot = build_snapshot(fetch_source())
    write_snapshot(args.output, snapshot)
    print(json.dumps(snapshot["Counts"]))
    print(f"Source SHA-256: {snapshot['SourceSHA256']}")


if __name__ == "__main__":
    main()
