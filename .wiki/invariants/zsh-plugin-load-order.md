---
type: Invariant
title: zsh enhancements must load in a fixed order
description: completions reach $fpath before compinit; fast-syntax-highlighting is sourced last of all ZLE-widget plugins.
tags: [zsh, shell]
timestamp: 2026-07-13T18:18:21Z
sources: [.zshrc]
source_commit: 079fc9a1170fec06e93de4981e1c4ac5ef94fc18
---

# Statement

`.zshrc` must preserve two ordering constraints:

1. **`zsh-completions` is added to `$fpath` *before* `compinit` runs.** Oh My Zsh
   runs `compinit` inside `oh-my-zsh.sh`, so the `FPATH=…zsh-completions` line
   must come *before* `source $ZSH/oh-my-zsh.sh`.
2. **`fast-syntax-highlighting` is sourced *last*** — after Oh My Zsh and after
   `zsh-autosuggestions`.

# Why

* The completion system reads `$fpath` only at `compinit` time; adding a
  directory afterward has no effect, so the extra completions silently don't load.
* fast-syntax-highlighting wraps *every* ZLE widget that exists when it loads.
  Anything that defines or rebinds widgets (Oh My Zsh, autosuggestions) must
  already be loaded, or its widgets aren't wrapped/highlighted correctly.

# Enforced by

Convention and comments in `.zshrc` only — there is no test. The `$BREW_PREFIX`
block (which prepends `zsh-completions` to `$fpath`, resolving the Homebrew
prefix once because it differs by CPU arch) sits above the `oh-my-zsh.sh` source;
the two `source …zsh-autosuggestions` / `…fast-syntax-highlighting` lines are the
last thing in the file, in that order.

# If violated

Completions or syntax highlighting quietly misbehave with no error — the shell
still starts, so the breakage is easy to miss and annoying to track down.
