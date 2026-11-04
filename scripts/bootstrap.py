#!/usr/bin/env python3
"""Fetch exact documentation-tool commits into .deps; never install runtime packages.

Pins and provenance come from PureMath develop; see build-dependencies.json.
Existing checkouts must be clean. Network operations are bounded by 180 seconds.
"""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def git(directory, *args):
    return subprocess.check_output(['git', '-C', str(directory), *args], text=True,
                                   stderr=subprocess.STDOUT, timeout=180).strip()


def main():
    manifest = json.loads((ROOT / 'scripts/build-dependencies.json').read_text())
    for dep in manifest['Dependencies']:
        target = ROOT / '.deps' / dep['Name']
        if not target.exists():
            target.mkdir(parents=True)
            git(target, 'init', '-q')
            git(target, 'remote', 'add', 'origin', dep['URL'])
        if git(target, 'remote', 'get-url', 'origin') != dep['URL']:
            raise RuntimeError(f'{target}: unexpected origin')
        if git(target, 'status', '--porcelain'):
            raise RuntimeError(f'{target}: working tree is not clean')
        try:
            current = git(target, 'rev-parse', 'HEAD')
        except subprocess.CalledProcessError:
            current = None
        if current != dep['Commit']:
            git(target, 'fetch', '-q', '--depth', '1', 'origin', dep['Commit'])
            git(target, 'checkout', '-q', '--detach', 'FETCH_HEAD')
        if git(target, 'rev-parse', 'HEAD') != dep['Commit']:
            raise RuntimeError(f'{target}: pin mismatch')
        print(f"{dep['Name']}: {dep['Commit']}")


if __name__ == '__main__':
    main()
