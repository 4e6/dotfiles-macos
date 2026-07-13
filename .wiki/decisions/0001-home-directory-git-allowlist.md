---
type: Decision
title: Track dotfiles with a git repo rooted in $HOME and a gitignore allowlist
description: The home directory itself is the working tree; .gitignore ignores everything, then re-includes an allowlist.
status: accepted
tags: [git, meta]
timestamp: 2026-07-13T18:18:21Z
---

# Context

Personal macOS config files live at their natural paths under `$HOME`
(`~/.zshrc`, `~/.hammerspoon/`, …). We want them version-controlled without
moving them out of the places the tools expect to find them.

# Decision

Make `$HOME` itself the git working tree. `.gitignore` ignores everything at the
root (`/*`) and then re-includes a small allowlist with `!` negation
(`!/.zshrc`, `!/.hammerspoon`, …). A file is tracked only once it is explicitly
opted in.

# Alternatives considered

* **Separate repo + symlinks (GNU stow, dotbot)** — rejected: adds a symlink
  layer and a manifest to maintain; the files no longer *are* the repo.
* **Bare repo + `alias dotfiles='git --git-dir=…'`** — rejected: the working
  tree is still `$HOME`, but every command needs the alias. The allowlist
  `.gitignore` gives the same "only tracked files show up" result with plain
  `git`.
* **chezmoi / yadm** — rejected: templating and a dedicated tool are more than a
  single-machine, single-user setup needs.

# Consequences

* **Deny-by-default is the safety property**: nothing in `$HOME` is ever tracked
  by accident (no stray secrets), at the cost of adding each new file to the
  allowlist by hand — including this wiki (`!/.wiki/`) and `!/CLAUDE.md`.
* Bootstrapping a new machine can't be a plain `git clone` (the tree already
  exists); it is `git init` + `git remote add` + `git checkout -f`. See the
  repo's `README.md`.
* Per-machine git identity is kept out of the tracked `.gitconfig` via an
  `[include]` of the untracked `~/.gitconfig.local`.
