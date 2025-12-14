<div align=center>
  <img width="512" alt="jumpr" src="https://github.com/user-attachments/assets/4d241d7f-c2ac-4b64-8e8b-b5f70ffeb919" />
</div>

---

Fuzzy search and execute prepopulated system actions from the CLI:
* Switch and close windows
* Launch applications
* Run system commands

<div align="center">
  <img width="1441" height="792" alt="image" src="https://github.com/user-attachments/assets/4be7577b-addf-4982-8190-3b8582ff37a5" />
</div>

## Table of Contents

- [Motivation](#motivation)
- [Installation](#installation)
- [Bindings](#bindings)
- [Uninstalling](#uninstalling)

## Motivation

Using the Gnome desktop, I started feeling that Alt-Tabbing is suboptimal compared to switching windows via search. Jumpr was born since none of the existing solutions fully met my expectations:
* [windows-search-provider](https://github.com/G-dH/windows-search-provider) - felt cumbersome to tab to a window, since windows are always _after_ applications in the list.
* [switcher](https://github.com/daniellandau/switcher) - the main conceptual drawback for me was the fact that Switcher view is not a window itself and stuff like window-scoped layout doesn't work in it.
* [rofi](https://github.com/davatorium/rofi), [Ulauncher](https://github.com/Ulauncher/Ulauncher), and other generic switchers - not switching windows with Gnome on Wayland.

## Installation

### 1. Install dependencies manually

Script dependencies:
* Gnome
* systemctl
* [window-calls](https://github.com/ickyicky/window-calls)
* [fzf](https://github.com/junegunn/fzf) >= 0.60.3
* [jq](https://github.com/jqlang/jq)
* (For the icons) [nerd-fonts](https://github.com/ryanoasis/nerd-fonts)

Installer dependencies:
* [kitty](https://github.com/kovidgoyal/kitty) >= 0.42.0

### 2. (Optional) Update configuration

Check the default installer configuration variables located at the top of the [installer.sh](./installer.sh) file and update them if necessary. One configuration option you may want to change is the shortcut key binding, which defaults to `<Super>Return`.

### 3. Run installer

After installing all dependencies and updating the configuration, run `./installer.sh install`

## Bindings

All standard `fzf` ones plus:
* `Esc` and `C-c` to hide input (enter "normal" mode)
* In normal mode:
    * `k` to go up one item
    * `j` to go down one item
    * `i` to show input
    * `D` to close window
    * `G` to go to the first item

Simple customizations can be added using `FZF_DEFAULT_OPTS="--bind '...'"` option.

## Uninstalling

To clean up all files populated by the installer, run `./installer.sh uninstall`.
* **Note** that at the moment shortcut needs to be removed manually.

