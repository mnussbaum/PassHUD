## PassHUD

A HUD-style fuzzy-finder interface for [zx2c4's
`pass`](https://www.passwordstore.org) on macOS. Copies passwords to clipboard.
Depends on `pass` being installed and configured.

![Screenshot](PassHUDScreenShot.png)

### Usage

Run the PassHUD application, then open PassHUD's window by clicking its lock
menu bar icon, or by using its default keyboard shorcut of `⌘ ` + `/`.

PassHUD fuzzy-finds passwords as you type. Click passwords to copy them to the
clipboard or just hit `Enter` once the password is highlighted. PassHUD keeps
recently used passwords at the top of the list for easy access.

Passwords are written to the clipboard directly by `pass` and are never seen by
PassHUD. Default `pass` clipboard clearing behavior applies.

### Installation

Download and install the latest release from a DMG on [the releases
page](https://github.com/mnussbaum/PassHUD/releases/).

### Configuration

PassHUD can be configured with an optional config file that can be created at
one of the following paths:

* `~/.PassHUD`
* `~/.config/PassHUD/config`

The config file is YAML and can set environment variables for PassHUD's
execution of `pass`, and an optional path to `pass` itself. If a path isn't
provided `pass` must be on the `$PATH`. All fields in the config are optional.
Here's an exhaustive example config file:

```yaml
---
version: 1

pass:
  commandPath: ~/a/non/default/path/to/pass
  env:
    - name: PASSWORD_STORE_DIR
      value: ~/a/non/default/password/store/path

# This example registers two arbitrary hot keys. Valid modifiers are: "cmd",
# "ctrl", "opt" and "shift"
hotKeys:
  - modifiers:
      - cmd
      - shift
    key: \
  - modifiers:
      - cmd
    key: /
 ```
