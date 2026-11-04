"""Registry ingestion preserves source metadata and fails before replacing a snapshot."""
import copy
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import updateSources as updater


def source_document():
    return {"apiVersion": "1.0", "errorMessage": None, "payload": {"namespaces": [{
        "id": 1, "prefix": "example", "name": "Synthetic example", "description": "Test fixture",
        "pattern": "^EX:[0-9]+$", "sampleId": "EX:1", "namespaceEmbeddedInLui": True,
        "deprecated": False, "renderDeprecatedLanding": False, "successor": None,
        "futureField": {"preserve": True}, "resources": [{
            "id": 2, "name": "Synthetic provider", "description": "Test fixture", "providerCode": "test",
            "urlPattern": "https://example.org/EX:{$id}", "sampleId": "1", "resourceHomeUrl": "https://example.org",
            "official": True, "deprecated": True, "protectedUrls": True,
            "renderDeprecatedLanding": False, "renderProtectedLanding": True,
            "authHelpUrl": "https://example.org/access", "authHelpDescription": None,
        }]
    }]}}


class SourceRegistryUpdate(unittest.TestCase):
    def snapshot(self, document):
        return updater.build_snapshot(json.dumps(document).encode(), "2026-01-01T00:00:00+00:00")

    def test_complete_records_flags_and_raw_byte_provenance(self):
        document = source_document()
        raw = json.dumps(document).encode()
        with patch.object(updater.urllib.request, "urlopen", side_effect=AssertionError("network called")):
            snapshot = updater.build_snapshot(raw, "2026-01-01T00:00:00+00:00")
        self.assertEqual(snapshot["Records"], document["payload"]["namespaces"])
        self.assertEqual(snapshot["SourceSHA256"], hashlib.sha256(raw).hexdigest())
        self.assertEqual(snapshot["Counts"], {"Namespaces": 1, "Resources": 1,
                         "DeprecatedNamespaces": 0, "DeprecatedResources": 1, "ProtectedResources": 1})
        self.assertEqual(snapshot["License"], "CC-BY-4.0")

    def test_unknown_api_failure_and_empty_registry_fail(self):
        for change in ({"apiVersion": "2.0"}, {"errorMessage": "unavailable"},
                       {"payload": {"namespaces": []}}, {"payload": []}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.snapshot(source_document() | change)

    def test_duplicate_prefix_namespace_and_resource_ids_fail(self):
        for collision in ("prefix", "namespace", "resource"):
            document = source_document()
            first = document["payload"]["namespaces"][0]
            second = copy.deepcopy(first)
            second.update(id=3, prefix="other")
            second["resources"][0]["id"] = 4
            if collision == "prefix": second["prefix"] = first["prefix"]
            if collision == "namespace": second["id"] = first["id"]
            if collision == "resource": second["resources"][0]["id"] = first["resources"][0]["id"]
            document["payload"]["namespaces"].append(second)
            with self.subTest(collision=collision), self.assertRaises(ValueError):
                self.snapshot(document)

    def test_missing_flags_and_boolean_ids_are_rejected(self):
        for field, value, nested in (("deprecated", None, False), ("id", True, False),
                                     ("protectedUrls", "false", True), ("resources", {}, False)):
            document = source_document()
            record = document["payload"]["namespaces"][0]
            if nested: record = record["resources"][0]
            record[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.snapshot(document)

    def test_prefixes_match_the_runtime_identifier_contract(self):
        for prefix in ("Example", "other/example", "example:", "example space", ""):
            document = source_document()
            document["payload"]["namespaces"][0]["prefix"] = prefix
            with self.subTest(prefix=prefix), self.assertRaises(ValueError):
                self.snapshot(document)

    def test_fetch_has_timeout_and_byte_bound(self):
        for source, oversized in ((b"1234", False), (b"123456", True)):
            with self.subTest(oversized=oversized), patch.object(updater, "MAX_BYTES", 4), \
                    patch.object(updater.urllib.request, "urlopen", return_value=io.BytesIO(source)) as request:
                if oversized:
                    with self.assertRaises(ValueError): updater.fetch_source()
                else:
                    self.assertEqual(updater.fetch_source(), source)
                self.assertEqual(request.call_args.kwargs["timeout"], 30)

    def test_atomic_write_preserves_existing_file_on_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "identifiers.json"
            target.write_text("existing snapshot")
            with patch.object(updater.os, "replace", side_effect=OSError("interrupted")), self.assertRaises(OSError):
                updater.write_snapshot(target, self.snapshot(source_document()))
            self.assertEqual(target.read_text(), "existing snapshot")
            self.assertEqual(list(target.parent.iterdir()), [target])
            updater.write_snapshot(target, self.snapshot(source_document()))
            self.assertEqual(json.loads(target.read_text())["Counts"]["Namespaces"], 1)


if __name__ == "__main__":
    unittest.main()
