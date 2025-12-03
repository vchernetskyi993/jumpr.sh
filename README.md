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

## Motivation

Using the Gnome desktop, I started feeling that Alt-Tabbing is suboptimal compared to switching windows via search. None of the existing solutions fully met my expectations:
* [windows-search-provider](https://github.com/G-dH/windows-search-provider) - felt cumbersome to tab to a window, since windows are always _after_ applications in the list.
* [switcher](https://github.com/daniellandau/switcher) - the main conceptual drawback for me was the fact that Switcher view is not a window itself and stuff like window-scoped layout doesn't work in it.
* [rofi](https://github.com/davatorium/rofi), [Ulauncher](https://github.com/Ulauncher/Ulauncher), and other generic switchers - not switching windows with Gnome on Wayland.

## Installation

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

