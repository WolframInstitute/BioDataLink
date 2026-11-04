"""Independent examples for the release safety boundary; no network or Wolfram required."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from validate_release import select_ci_run, validate_tag


class ReleaseValidation(unittest.TestCase):
    def test_matching_version(self):
        self.assertEqual(validate_tag('v0.1.0', '"Version" -> "0.1.0",'), '0.1.0')

    def test_wrong_or_malformed_tag(self):
        for tag in ('v0.2.0', '0.1.0', 'v0.1.0-extra', 'v0.1'):
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                validate_tag(tag, '"Version" -> "0.1.0",')

    def test_missing_or_duplicate_version(self):
        for info in ('', '"Version" -> "0.1.0"\n"Version" -> "0.1.0"'):
            with self.assertRaises(ValueError):
                validate_tag('v0.1.0', info)

    def test_exact_main_push_required(self):
        valid = dict(databaseId=12, headSha='abc', headBranch='main',
                     event='push', conclusion='success')
        self.assertEqual(select_ci_run([valid], 'abc'), 12)
        for key, value in [('headSha', 'def'), ('headBranch', 'feature'),
                           ('event', 'workflow_dispatch'), ('conclusion', 'failure')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                select_ci_run([{**valid, key: value}], 'abc')

    def test_missing_run(self):
        with self.assertRaises(ValueError):
            select_ci_run([], 'abc')


if __name__ == '__main__':
    unittest.main()
