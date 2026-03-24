#!/bin/bash
jq -r '.[0] | "Abide\(if .from then " \(.from)" else "" end): \(.text)"' "$1/dudes/inbox.json"
