#!/usr/bin/env bash
# Prints the UDID of an available iPhone simulator on the newest installed iOS runtime.
set -euo pipefail

xcrun simctl list devices available --json | python3 -c '
import json, sys

devices = json.load(sys.stdin)["devices"]

def version(runtime):
    return tuple(int(part) for part in runtime.rsplit(".", 1)[-1].split("-")[1:])

for runtime in sorted((r for r in devices if ".iOS-" in r), key=version, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)

sys.exit("No available iPhone simulator found.")
'
