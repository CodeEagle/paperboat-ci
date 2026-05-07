#!/usr/bin/env bash
# Local decryption helper. Mirrors what ci/decrypt-source.sh does, but reads the
# key from a file (instead of an env var) so it's safer to run from a shell.
#
# Usage:
#   tools/decrypt-source.sh <ENC_FILE> <KEY_FILE> <OUT_DIR>
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <ENC_FILE> <KEY_FILE> <OUT_DIR>" >&2
  exit 2
fi

ENC="$1"
KEY="$2"
OUT="$3"

if [[ ! -f "$ENC" ]]; then
  echo "error: enc file not found: $ENC" >&2
  exit 1
fi
if [[ ! -f "$KEY" ]]; then
  echo "error: key file not found: $KEY" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -in "$ENC" \
  -pass "file:$KEY" \
  | tar -xzf - -C "$OUT"

echo "decrypted into: $OUT"
