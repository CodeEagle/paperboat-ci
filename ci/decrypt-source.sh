#!/usr/bin/env bash
# CI-side decryption: reads SOURCE_KEY from env, decrypts encrypted/source.tar.gz.enc into ./src/
set -euo pipefail

if [[ -z "${SOURCE_KEY:-}" ]]; then
  echo "::error::SOURCE_KEY env var is empty"
  exit 1
fi

ENC_FILE="encrypted/source.tar.gz.enc"
if [[ ! -f "$ENC_FILE" ]]; then
  echo "::error::$ENC_FILE not found"
  exit 1
fi

OUT_DIR="src"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Pipe key via stdin to openssl to avoid leaking via process listing
printf '%s' "$SOURCE_KEY" | openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -salt \
  -in "$ENC_FILE" \
  -pass stdin \
  | tar -xzf - -C "$OUT_DIR"

unset SOURCE_KEY

if [[ ! -e "$OUT_DIR/project.yml" ]]; then
  echo "::error::Decrypted source missing project.yml — wrong key or corrupt archive"
  exit 1
fi

if [[ ! -e "$OUT_DIR/PaperBoatShared/Package.swift" ]]; then
  echo "::warning::PaperBoatShared/Package.swift not present in the encrypted source; swift test step will fail. Re-encrypt from a dev environment that has Package.swift."
fi

echo "Source decrypted into $OUT_DIR/"
