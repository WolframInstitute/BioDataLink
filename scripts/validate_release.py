#!/usr/bin/env python3
"""Validate release metadata and select exact-commit successful main CI runs."""
from __future__ import annotations
import argparse
import json
import re
import subprocess
from pathlib import Path

VERSION = re.compile(r'"Version"\s*->\s*"(\d+\.\d+\.\d+)"')
TAG = re.compile(r'v\d+\.\d+\.\d+')


def validate_tag(tag: str, paclet_info: str) -> str:
    versions = VERSION.findall(paclet_info)
    if len(versions) != 1 or TAG.fullmatch(tag) is None or tag != 'v' + versions[0]:
        raise ValueError('Tag must match the unique MAJOR.MINOR.PATCH Version in PacletInfo.wl')
    return versions[0]


def select_ci_run(runs: list[dict], commit: str) -> int:
    for run in runs:
        if (run.get('headSha') == commit and run.get('headBranch') == 'main'
                and run.get('event') == 'push' and run.get('conclusion') == 'success'):
            return int(run['databaseId'])
    raise ValueError('No successful push CI run on main for the exact tagged commit')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('tag')
    parser.add_argument('--info', type=Path, default=Path('BioDataLink/PacletInfo.wl'))
    parser.add_argument('--require-ci', action='store_true')
    args = parser.parse_args()
    try:
        version = validate_tag(args.tag, args.info.read_text())
        if args.require_ci:
            commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
            runs = json.loads(subprocess.check_output([
                'gh', 'run', 'list', '--workflow', 'ci.yml', '--branch', 'main',
                '--commit', commit, '--event', 'push', '--status', 'success', '--limit', '20',
                '--json', 'databaseId,headSha,headBranch,event,conclusion'
            ], text=True))
            print(select_ci_run(runs, commit))
        else:
            print(version)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'Release validation failed: {error}\n')


if __name__ == '__main__':
    main()
