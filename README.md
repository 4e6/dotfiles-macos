# dotfiles

Personal macOS dotfiles. The repository lives directly in `$HOME` and tracks a
small allowlist of config files — everything else in the home directory is
ignored by default (see [`.gitignore`](.gitignore), which ignores `/*` and then
re-includes only the files below).

## What's included

| Path | Purpose |
|------|---------|
| `.gitconfig` | Git settings, colors, and a large set of aliases. Includes `~/.gitconfig.local` for the per-machine user identity. |
| `.gitignore` | The home-directory allowlist (ignore everything, opt files back in). |
| `.zshrc` | Zsh / Oh My Zsh configuration. |
| `Brewfile` | Homebrew packages & casks, installable in one go with `brew bundle`. |
| `.hammerspoon/` | [Hammerspoon](https://www.hammerspoon.org/) automation (see below). |
| `.local/share/trainingpeaks-mcp/` | The [TrainingPeaks MCP server](https://github.com/JamsusMaximus/trainingpeaks-mcp), a submodule pinned to a reviewed commit, for Claude Code and Codex (see below). |
| `.local/share/open-notebook-mcp/` | The [Open Notebook MCP server](https://github.com/Epochal-dev/open-notebook-mcp), a submodule pinned to a reviewed commit, giving Claude Code access to the local Open Notebook in `~/projects/4e6/open-notebook` (see below). |

### Hammerspoon keybindings

Configured in `.hammerspoon/`:

| Shortcut | Action |
|----------|--------|
| `Ctrl/Option + 1…9, 0` | Switch to Desktop 1–10 (`0` = Desktop 10) |
| `Option + Shift + 1…9, 0` | Move the focused window to Desktop N (`0` = Desktop 10) |
| `Option + H / J / K / L` | Focus the window to the left / down / up / right |
| `Command + F1 / F2` | Dim / brighten the keyboard backlight one step |
| `Command + F6` | Sleep the Mac like closing the lid — or, if `caffeinate` is running, just lock the screen |

> Desktop 10 (`0`) only works once you map it in macOS: *System Settings →
> Keyboard → Keyboard Shortcuts → Mission Control → "Switch to Desktop 10" =
> `Ctrl+0`.* macOS auto-assigns `Ctrl+1`…`Ctrl+9` but not `Ctrl+0`.

## Initial setup on a new Mac

### 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Oh My Zsh

[Oh My Zsh](https://ohmyz.sh/) manages the zsh configuration:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

The installer creates/overwrites `~/.zshrc` from its template, backing up any
existing one to `~/.zshrc.pre-oh-my-zsh`.

### 3. Clone this repo into `$HOME`

Because the working tree is the home directory itself (which already contains
files), set the remote up in place rather than a plain `git clone`:

```bash
cd ~
git init
git remote add origin <YOUR_REPO_URL>
git fetch origin
git checkout -f main      # -f overwrites the tracked dotfiles with the repo versions
git submodule update --init
```

Only the allowlisted files are touched; the rest of your home directory is left
alone.

### 4. Set your Git identity (per machine)

`~/.gitconfig.local` is intentionally **not** tracked, so each machine sets its
own identity. Create it:

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
	name = Your Name
	email = you@example.com
EOF
```

### 5. Install packages

```bash
brew bundle install --file=~/Brewfile
```

This installs everything in the `Brewfile`, including Hammerspoon.

### 6. Enable Hammerspoon

1. Launch **Hammerspoon** (installed in the previous step).
2. Grant it **Accessibility** permission:
   *System Settings → Privacy & Security → Accessibility → enable Hammerspoon.*
   (Required for the window/desktop shortcuts.)
3. Click the menu-bar icon → **Reload Config**.

The `hs` command-line tool is enabled automatically (`require("hs.ipc")` in
`init.lua`), so `hs -c "..."` works from the terminal after a reload.

### 7. Set up the TrainingPeaks MCP server

The submodule holds the source; its environment is built per machine, with
Homebrew's Python (the system `python3` is too old), and is ignored by the
submodule's own `.gitignore`:

```bash
TP=~/.local/share/trainingpeaks-mcp
/opt/homebrew/bin/python3.14 -m venv $TP/.venv
$TP/.venv/bin/pip install -e "$TP[browser]"
$TP/.venv/bin/tp-mcp auth --from-browser chrome   # stores the cookie in the Keychain
```

Then register it with both assistants. Their config files (`~/.claude.json`,
`~/.codex/config.toml`) are machine state and are not tracked, so this is the
record of what goes in them:

```bash
claude mcp add --scope user trainingpeaks -- $TP/.venv/bin/tp-mcp serve
codex mcp add trainingpeaks -- $TP/.venv/bin/tp-mcp serve
```

### 8. Set up the Open Notebook MCP server

Needs Open Notebook running (`docker compose up -d` in
`~/projects/4e6/open-notebook`, see its README). Same layout as TrainingPeaks:
source in the submodule, per-machine `.venv`. Upstream doesn't cap its `mcp`
dependency and the code needs the 1.x API (`mcp.server.fastmcp`), so pin it:

```bash
ON=~/.local/share/open-notebook-mcp
/opt/homebrew/bin/python3.14 -m venv $ON/.venv
$ON/.venv/bin/pip install -e "$ON" "mcp[cli]>=1.23.2,<2"
claude mcp add --scope user open-notebook -e OPEN_NOTEBOOK_URL=http://localhost:5055 \
  -- $ON/.venv/bin/open-notebook-mcp
```

## Updating the TrainingPeaks MCP server

The submodule is pinned, so an update is a commit here, made after reading what
changed:

```bash
cd ~
git submodule update --remote .local/share/trainingpeaks-mcp
git diff --submodule=log .local/share/trainingpeaks-mcp     # what is coming in
git -C .local/share/trainingpeaks-mcp diff HEAD@{1} --stat -- pyproject.toml
```

The install is editable, so source changes take effect on the next start of
Claude Code or Codex. Only when `pyproject.toml` changed, reinstall:
`~/.local/share/trainingpeaks-mcp/.venv/bin/pip install -e "$HOME/.local/share/trainingpeaks-mcp[browser]"`.
Then commit the bump.

## Maintaining the Brewfile

After installing or removing Homebrew packages, regenerate the list:

```bash
brew bundle dump --force --file=~/Brewfile
```

Other useful commands:

- `brew bundle check --file=~/Brewfile` — report what's missing.
- `brew bundle cleanup --file=~/Brewfile` — list packages not in the Brewfile
  (add `--force` to uninstall them).
