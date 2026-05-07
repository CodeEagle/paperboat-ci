#!/usr/bin/env bash
# Encrypt the project source tree into a single openssl-encrypted tarball.
#
# Usage:
#   tools/encrypt-source.sh <SOURCE_ROOT> <KEY_FILE> <OUT_PATH>
#
# - SOURCE_ROOT: path to the private project root (must contain project.yml + PaperBoatShared/)
# - KEY_FILE:    file holding the passphrase (must be a single line of bytes; no trailing newline preferred)
# - OUT_PATH:    output .enc path
#
# Cipher: AES-256-CBC + PBKDF2 (100k iters) + random salt. openssl-only, zero deps.
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <SOURCE_ROOT> <KEY_FILE> <OUT_PATH>" >&2
  exit 2
fi

SOURCE_ROOT="$1"
KEY_FILE="$2"
OUT_PATH="$3"

if [[ ! -d "$SOURCE_ROOT" ]]; then
  echo "error: source root not found: $SOURCE_ROOT" >&2
  exit 1
fi
if [[ ! -f "$KEY_FILE" ]]; then
  echo "error: key file not found: $KEY_FILE" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_ROOT/project.yml" ]]; then
  echo "error: $SOURCE_ROOT does not look like the PaperBoat project (no project.yml)" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_ROOT/PaperBoatShared/Package.swift" ]]; then
  echo "warning: $SOURCE_ROOT/PaperBoatShared/Package.swift is missing — CI 'swift test' will fail" >&2
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Build a tar of the source. Exclude generated/cache/CI artefacts and anything that
# could leak credentials. Use --exclude-vcs to drop .git history.
tar -czf "$WORK/src.tar.gz" \
  --exclude-vcs \
  --exclude='.build' \
  --exclude='.swiftpm' \
  --exclude='DerivedData' \
  --exclude='*.xcodeproj' \
  --exclude='.DS_Store' \
  --exclude='.acc' \
  --exclude='.claude' \
  --exclude='.asc' \
  --exclude='build' \
  --exclude='.worktrees' \
  --exclude='public-repo' \
  --exclude='.netrc' \
  --exclude='.env' \
  --exclude='.env.local' \
  --exclude='node_modules' \
  -C "$SOURCE_ROOT" \
  .

mkdir -p "$(dirname "$OUT_PATH")"
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -in "$WORK/src.tar.gz" \
  -out "$OUT_PATH" \
  -pass "file:$KEY_FILE"

size_h=$(du -h "$OUT_PATH" | cut -f1)
echo "encrypted: $OUT_PATH ($size_h)"
