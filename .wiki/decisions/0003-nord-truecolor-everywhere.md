---
type: Decision
title: Standardize on the Nord theme in 24-bit truecolor
description: Vim, Ghostty, and airline all target Nord in truecolor; Apple Terminal.app is the excluded edge case.
status: accepted
tags: [theme, vim, ghostty]
timestamp: 2026-07-13T18:18:21Z
---

# Context

Several tools render color independently — the terminal emulator and Vim's
colorscheme. We want one consistent look instead of per-tool palettes that clash.

# Decision

Target the **Nord** palette everywhere, rendered in **24-bit truecolor**:
Ghostty `theme = nord`, Vim `colorscheme nord`, airline theme `nord`.

# Alternatives considered

* **256-color fallback** — rejected on capable terminals: Nord's intended comment
  color (`#616E88`) degrades to a dim, hard-to-read 256-color approximation.
  Truecolor is what makes Nord look as designed.

# Consequences

* **Apple Terminal.app is the one excluded environment** — it has no truecolor
  support, so `.vimrc` enables `termguicolors` only when
  `$TERM_PROGRAM != 'Apple_Terminal'`. Ghostty (and iTerm2/WezTerm) render
  truecolor by default.
* **Ordering matters in Vim**: `termguicolors` must be set *before* `plugins.vim`
  runs `colorscheme nord`, or Nord initializes against the wrong color depth.
* Non-macOS hosts fall back to **Zenburn** (both `colorscheme` and the airline
  theme branch on `has('mac')`), since Nord was chosen for the Mac setup.
