# Decision

* [Drive desktop/window actions by synthesizing native macOS shortcuts](0002-synthesize-native-macos-shortcuts.md) - Hammerspoon posts the native Ctrl+digit key events instead of calling hs.spaces navigation APIs.
* [Standardize on the Nord theme in 24-bit truecolor](0003-nord-truecolor-everywhere.md) - Vim, Ghostty, and airline all target Nord in truecolor; Apple Terminal.app is the excluded edge case.
* [Store git credentials in the macOS Keychain, not a plaintext file](0004-credentials-in-macos-keychain.md) - credential.helper is osxkeychain; the `store` helper's plaintext ~/.git-credentials is rejected, especially now that the repo is public.
* [Track dotfiles with a git repo rooted in $HOME and a gitignore allowlist](0001-home-directory-git-allowlist.md) - The home directory itself is the working tree; .gitignore ignores everything, then re-includes an allowlist.
