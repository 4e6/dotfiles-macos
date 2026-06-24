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
| `Brewfile` | Homebrew packages & casks, installable in one go with `brew bundle`. |
| `.hammerspoon/` | [Hammerspoon](https://www.hammerspoon.org/) automation (see below). |

### Hammerspoon keybindings

Configured in `.hammerspoon/` (`init.lua` loads `spaces.lua` and
`window_focus.lua`):

| Shortcut | Action |
|----------|--------|
| `Ctrl/Option + 1…6` | Switch to Desktop 1–6 |
| `Option + Shift + 1…6` | Move the focused window to Desktop N |
| `Option + H / J / K / L` | Focus the window to the left / down / up / right |

## Initial setup on a new Mac

### 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Clone this repo into `$HOME`

Because the working tree is the home directory itself (which already contains
files), set the remote up in place rather than a plain `git clone`:

```bash
cd ~
git init
git remote add origin <YOUR_REPO_URL>
git fetch origin
git checkout -f main      # -f overwrites the tracked dotfiles with the repo versions
```

Only the allowlisted files are touched; the rest of your home directory is left
alone.

### 3. Set your Git identity (per machine)

`~/.gitconfig.local` is intentionally **not** tracked, so each machine sets its
own identity. Create it:

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
	name = Your Name
	email = you@example.com
EOF
```

### 4. Install packages

```bash
brew bundle install --file=~/Brewfile
```

This installs everything in the `Brewfile`, including Hammerspoon.

### 5. Enable Hammerspoon

1. Launch **Hammerspoon** (installed in the previous step).
2. Grant it **Accessibility** permission:
   *System Settings → Privacy & Security → Accessibility → enable Hammerspoon.*
   (Required for the window/desktop shortcuts.)
3. Click the menu-bar icon → **Reload Config**.

The `hs` command-line tool is enabled automatically (`require("hs.ipc")` in
`init.lua`), so `hs -c "..."` works from the terminal after a reload.

## Maintaining the Brewfile

After installing or removing Homebrew packages, regenerate the list:

```bash
brew bundle dump --force --file=~/Brewfile
```

Other useful commands:

- `brew bundle check --file=~/Brewfile` — report what's missing.
- `brew bundle cleanup --file=~/Brewfile` — list packages not in the Brewfile
  (add `--force` to uninstall them).
