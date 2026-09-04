# ActionClip Homebrew Tap

This is the official Homebrew tap for [ActionClip](https://actionclip.app/), a
native macOS app that puts contextual actions beside selected text.

## Install

```sh
brew install --cask gopublisher/tap/actionclip
```

On Homebrew 6 and later, that fully qualified install command trusts only the
ActionClip cask. It does not grant trust to every current or future item in the
tap.

ActionClip requires macOS 15 Sequoia or later. Homebrew downloads the same
Developer ID-signed and Apple-notarized DMG published on the ActionClip website.

## Update

ActionClip can update itself through its built-in Sparkle updater. To explicitly
replace it with the newest cask through Homebrew, run:

```sh
brew upgrade --cask --greedy-auto-updates gopublisher/tap/actionclip
```

## Uninstall

```sh
brew uninstall --cask actionclip
```

To also remove local ActionClip settings and user-created actions:

```sh
brew uninstall --zap --cask actionclip
```

`--zap` is destructive and is not needed for a normal uninstall or reinstall.

## Release maintenance

The cask tracks ActionClip's stable Sparkle feed. A scheduled workflow checks
the public release metadata, verifies the DMG checksum, validates the updated
cask, and commits version updates. It stops instead of changing the checksum if
a published version URL is ever reused.
