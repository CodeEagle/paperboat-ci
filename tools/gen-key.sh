#!/usr/bin/env bash
# Generate a fresh 256-bit symmetric key, base64-encoded, written to <key_file>.
# Usage:  tools/gen-key.sh <key_file>
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <key_file>" >&2
  exit 2
fi

KEY_FILE="$1"

if [[ -e "$KEY_FILE" ]]; then
  echo "error: $KEY_FILE already exists; remove it first if you want to rotate" >&2
  exit 1
fi

mkdir -p "$(dirname "$KEY_FILE")"
# 32 random bytes, base64 encoded, single line, no trailing newline
openssl rand -base64 32 | tr -d '\n' > "$KEY_FILE"
chmod 600 "$KEY_FILE"
echo "key written to $KEY_FILE (mode 600)"
echo "Reminder: store this value in GitHub Actions secret SOURCE_KEY for the public repo."
