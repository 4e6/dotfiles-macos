---
type: Decision
title: Store git credentials in the macOS Keychain, not a plaintext file
description: credential.helper is osxkeychain; the `store` helper's plaintext ~/.git-credentials is rejected, especially now that the repo is public.
status: accepted
tags: [git, security, macos]
timestamp: 2026-08-23T14:24:46Z
---

# Context

`.gitconfig` is tracked and published, so its `[credential]` setting is not just
a local preference — it is advice every person who clones these dotfiles inherits
and applies to their own accounts.

The previous value was `helper = store`. That helper writes credentials as
**cleartext** to `~/.git-credentials`: for GitHub over HTTPS that means a live
OAuth/PAT token sitting on disk, readable by any process running as the user and
by anything that sweeps `$HOME` (backups, sync agents, malicious postinstall
scripts). The allowlist in [decision 0001](0001-home-directory-git-allowlist.md)
keeps that file out of git, but being un-committed is not the same as being safe.

# Decision

Set `credential.helper = osxkeychain`. Credentials go to the login Keychain,
which is encrypted at rest and access-controlled per application.

# Alternatives considered

* **`store`** — rejected: plaintext on disk, and publishing it recommends the
  same to everyone who clones this repo.
* **`cache`** — in-memory and safe, but it forgets on a timeout (default 15 min),
  so it trades away the convenience the helper exists to provide.
* **Leaving it unset** — git would prompt on every HTTPS operation.

# Consequences

* `git-credential-osxkeychain` ships with git on macOS, so no extra install —
  but this line is **macOS-specific**, matching the rest of these dotfiles.
* **Existing `~/.git-credentials` is now ignored, not deleted.** Git stops
  reading it, so any token in it is stale but still on disk in cleartext. Delete
  it (`rm ~/.git-credentials`) and rotate anything it held.
* The first HTTPS push after this change re-prompts once, then the Keychain
  answers subsequent ones.
* `gh` is unaffected — it keeps its own token in the keyring independently.
