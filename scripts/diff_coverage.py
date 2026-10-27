#!/usr/bin/env python3
"""Fails when the lines changed since a base commit are not covered enough by tests.

Reads line coverage from an .xcresult bundle with `xccov`, intersects it with the lines
added or modified since `--base` (whitespace-only changes ignored), and compares the result
to `--min`. Files matching a glob in `--ignore-file` are left out. Lines that are not
executable (comments, braces, declarations) never count, and neither do files the coverage
report does not list, which have no executable code.
"""

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def changed_lines(base, source_dir):
    try:
        merge_base = run("git", "merge-base", base, "HEAD").strip()
    except subprocess.CalledProcessError:
        sys.exit(f"Base '{base}' is not in the local history. Fetch it (CI needs fetch-depth: 0) or pass another --base.")
    diff = run(
        "git", "diff", "--unified=0", "--ignore-all-space", "--diff-filter=AM", merge_base, "--", f"{source_dir}/*.swift"
    )

    changes, current = {}, None
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[4:]
            current = path[2:] if path.startswith("b/") else None
        elif line.startswith("@@") and current:
            match = re.search(r"\+(\d+)(?:,(\d+))?", line)
            start, count = int(match.group(1)), int(match.group(2) or 1)
            changes.setdefault(current, set()).update(range(start, start + count))
    return changes


def ignored_patterns(path):
    if not path or not os.path.exists(path):
        return []
    with open(path) as file:
        return [line.strip() for line in file if line.strip() and not line.startswith("#")]


def covered_files(xcresult):
    return run("xcrun", "xccov", "view", "--archive", "--file-list", xcresult).split()


def line_coverage(xcresult, absolute_path):
    report = json.loads(run("xcrun", "xccov", "view", "--archive", "--json", "--file", absolute_path, xcresult))
    lines = next(iter(report.values())) if isinstance(report, dict) else report
    return {entry["line"]: entry.get("executionCount", 0) for entry in lines if entry.get("isExecutable")}


def total_coverage(xcresult, target):
    report = json.loads(run("xcrun", "xccov", "view", "--report", "--json", xcresult))
    for item in report.get("targets", []):
        if item["name"].startswith(target):
            return item["lineCoverage"] * 100
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xcresult", required=True)
    parser.add_argument("--base", required=True, help="commit or ref the changes are compared to")
    parser.add_argument("--source-dir", default="kmais-app-ios")
    parser.add_argument("--min", type=float, default=80.0)
    parser.add_argument("--ignore-file", default=".coverageignore")
    args = parser.parse_args()

    patterns = ignored_patterns(args.ignore_file)
    changes = {
        path: lines
        for path, lines in changed_lines(args.base, args.source_dir).items()
        if not any(fnmatch.fnmatch(path, pattern) for pattern in patterns)
    }
    archived = covered_files(args.xcresult)

    rows, executable, covered = [], 0, 0
    for path, lines in sorted(changes.items()):
        absolute = next((file for file in archived if file.endswith("/" + path)), None)
        if not absolute:
            continue
        coverage = line_coverage(args.xcresult, absolute)
        relevant = sorted(line for line in lines if line in coverage)
        if not relevant:
            continue

        missed = [line for line in relevant if coverage[line] == 0]
        executable += len(relevant)
        covered += len(relevant) - len(missed)
        rows.append((path, len(relevant), len(relevant) - len(missed), missed))

    total = total_coverage(args.xcresult, args.source_dir)
    summary = [f"Overall line coverage of `{args.source_dir}`: {total:.1f}%" if total is not None else ""]

    if executable == 0:
        summary.append("No executable lines changed outside the ignored files — nothing to check.")
        passed = True
    else:
        percent = covered / executable * 100
        passed = percent >= args.min
        summary += [
            "",
            "| File | Changed executable lines | Covered | Uncovered lines |",
            "|---|---|---|---|",
            *[
                f"| `{path}` | {total_lines} | {hit} | {', '.join(map(str, missed)) or '—'} |"
                for path, total_lines, hit, missed in rows
            ],
            "",
            f"**Coverage of changed lines: {percent:.1f}% ({covered}/{executable}) — minimum {args.min:.0f}%**",
        ]

    report = "\n".join(summary)
    print(report)
    if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(summary_path, "a") as file:
            file.write("## Coverage\n\n" + report + "\n")

    if not passed:
        print(f"\nChanged lines are below the {args.min:.0f}% coverage minimum.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
