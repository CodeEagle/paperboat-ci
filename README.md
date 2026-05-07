# paperboat-ci

CI mirror for **PaperBoat** (a private iOS + macOS EPUB reader). The source tree
is shipped here as an AES-256-CBC encrypted tarball; GitHub Actions decrypts it
on the runner using a repository secret and runs the test suite.

This repository is **not** the project source. It exists to take advantage of
the free CI minutes available on public repositories. The encrypted blob in
`encrypted/source.tar.gz.enc` cannot be read without the symmetric key, which
is held only in the `SOURCE_KEY` GitHub Actions secret and on the maintainer's
local workstation.

## Repository layout

```
.github/workflows/test.yml     CI workflow (decrypt → build → test)
ci/decrypt-source.sh           Runs on the CI runner; reads SOURCE_KEY from env
encrypted/source.tar.gz.enc    Encrypted source archive
tools/encrypt-source.sh        Local: encrypt a source tree into the .enc blob
tools/decrypt-source.sh        Local: decrypt the blob using a key file
tools/gen-key.sh               Local: generate a fresh random key
```

## How the CI runs

1. Workflow checks out this repository.
2. `ci/decrypt-source.sh` reads `SOURCE_KEY` from the GitHub Actions secret,
   decrypts `encrypted/source.tar.gz.enc` with `openssl enc -d -aes-256-cbc
   -pbkdf2`, and extracts the tarball into `src/`.
3. `xcodegen generate` regenerates `PaperBoat.xcodeproj` inside `src/`.
4. `swift test` runs the shared package tests; `xcodebuild test` runs the iOS
   tests; `xcodebuild build` verifies the macOS target.
5. The runner is destroyed at the end of the job; nothing decrypted persists.

CI logs are public on this repository, so build / test failures may print
fragments of source through stack traces and compiler errors. This is an
accepted trade-off — only run CI on commits you have already verified locally.

## Maintainer workflow

From the private repository root:

```sh
# One-time: generate a 256-bit base64 key and store it somewhere safe outside both repos.
public-repo/tools/gen-key.sh ~/.paperboat-ci-key

# Each time you want to update the encrypted source on this public repo:
scripts/publish-encrypted.sh
```

`publish-encrypted.sh` clones this repo to a tempdir, regenerates
`encrypted/source.tar.gz.enc` from the current private working tree, commits,
and pushes to `main`.

## Threat model

| Threat | Mitigation |
| --- | --- |
| Anyone reads the encrypted blob | AES-256-CBC + PBKDF2 (100k iterations); without the key the blob is opaque. |
| GitHub Actions secret leaks via logs | The decrypt step pipes the secret to `openssl` over stdin and unsets the env var afterwards. |
| Pull requests from forks try to read the secret | Workflow only triggers on `push` to `main` and on `workflow_dispatch`. Forked PRs do not get secrets. |
| Build artifacts smuggle source out | The runner is ephemeral and no artifacts are uploaded. |
| Key rotation | Re-run `gen-key.sh` to a new file, re-encrypt, push, then update the `SOURCE_KEY` secret in this repo's settings. Rotate the secret first if you suspect compromise. |

## License

The encrypted blob, the workflow, and the helper scripts are All Rights
Reserved by the project owner. Ciphertext does not constitute a public
licence to the underlying source.
