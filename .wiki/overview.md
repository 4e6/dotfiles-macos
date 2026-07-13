---
type: Overview
title: dotfiles — personal macOS environment
description: Version-controlled macOS config living directly in $HOME, tracked via a gitignore allowlist.
tags: [meta, macos]
timestamp: 2026-07-13T18:18:21Z
---

# What this is

Personal macOS dotfiles. The git repository is rooted **directly in `$HOME`**:
the working tree is the home directory itself, and a `.gitignore` allowlist keeps
everything untracked *except* a hand-picked set of config files. Why this layout
(and not a bare repo, a symlink farm, or chezmoi) is
[decision 0001](/decisions/0001-home-directory-git-allowlist.md).

The user-facing setup guide, keybinding tables, and `brew bundle` maintenance
commands live in the repo's `README.md` and are not duplicated here. This
wiki holds the *why* behind the config and the sharp edges that cost time —
things the files themselves can't say.

# Components

| Area | Tracked files | Durable knowledge here |
|---|---|---|
| Window/desktop automation | `.hammerspoon/**` | [Hammerspoon module](/architecture/hammerspoon.md) — the one part with real logic |
| Shell | `.zshrc` | [zsh plugin load order](/invariants/zsh-plugin-load-order.md) invariant |
| Editor | `.vimrc`, `.vim/plugins.vim` | theme: [Nord + truecolor](/decisions/0003-nord-truecolor-everywhere.md) |
| Terminal | `.config/ghostty/config` | theme: [Nord + truecolor](/decisions/0003-nord-truecolor-everywhere.md) |
| Git | `.gitconfig` | per-machine identity via untracked `~/.gitconfig.local` — see [decision 0001](/decisions/0001-home-directory-git-allowlist.md) |
| GPG | `.gnupg/gpg-agent.conf` | one line: `pinentry-mac` for GUI passphrase entry |
| Packages | `Brewfile` | installed with `brew bundle`; contents are self-describing |

# Theme through-line

Vim, Ghostty, and airline all target the **Nord** palette rendered in 24-bit
truecolor; the single environment that shaped the config is Apple Terminal.app,
which has no truecolor. See
[decision 0003](/decisions/0003-nord-truecolor-everywhere.md).

# Bootstrapping

A new machine is set up by pointing a fresh `git init` in `$HOME` at the remote
and running `git checkout -f` — details in the repo's `README.md`. The wiki
bundle in `.wiki/` is committed alongside the config, so a change and the
knowledge about it land in the same commit.
