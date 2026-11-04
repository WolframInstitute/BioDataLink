"""The catalog refresh reads declarations without executing upstream code."""
import sys
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from updateCatalog import extract

REVISION = 'a' * 40
SOURCE = '''
raise RuntimeError("Never execute the upstream module")
def example():
    """Processed expression measurements.

    References:
        Example et al. doi:10.0000/example
    Returns:
        AnnData
    """
    return _download(url="https://example.org/data.h5ad")
def _private():
    return _download(url="https://example.org/private.h5ad")
'''


class CatalogExtraction(unittest.TestCase):
    def test_metadata_and_provenance_without_execution(self):
        with patch('urllib.request.urlopen', side_effect=AssertionError('network called')):
            records = extract(SOURCE, REVISION)
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]['ID'], 'example')
        self.assertEqual(records[0]['DownloadURLs'], ['https://example.org/data.h5ad'])
        self.assertEqual(records[0]['Citation'], 'Example et al. doi:10.0000/example')
        self.assertEqual(records[0]['SourceRevision'], REVISION)
        self.assertFalse(records[0]['NativeImportSupported'])
        self.assertIsNone(records[0]['Organism'])

    def test_dynamic_and_insecure_urls_are_not_invented(self):
        for url in ('base + "/data.h5ad"', '"http://example.org/data.h5ad"'):
            with self.subTest(url=url), self.assertRaises(ValueError):
                extract(f'def example():\n    return _download(url={url})', REVISION)

    def test_unrelated_url_calls_are_not_dataset_artifacts(self):
        source = SOURCE + '\ndef annotation():\n    return fetch_metadata(url="https://example.org/api")\n'
        self.assertEqual([record['ID'] for record in extract(source, REVISION)], ['example'])

    def test_duplicate_ids_fail(self):
        with self.assertRaises(ValueError):
            extract(SOURCE + SOURCE, REVISION)

    def test_syntax_error_is_reported(self):
        with self.assertRaises(SyntaxError):
            extract('def example(:', REVISION)


if __name__ == '__main__':
    unittest.main()
