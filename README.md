# mouse-grid
A [Hammerspoon][1] module that lets you move the mouse pointer to a certain location on the screen by typing the hint for location instead of using the physcial mouse. 

Ever wanted to navigate your mac using only the keyboard? Tools like [vimium][2] and [vimac][3] get you close, but they only show hints on the actual UI elements on the screen. But what if you wanted to jump to an arbitrary location on the screen?

This module lets you bind a shortcut that displays a grid on the screen with a hint for each cell. Using the shortcut repeatedly rotates the grid onto additional monitors, and typing the hint or ESC closes the grid. The idea is that once you are on the desired monitor/screen, you type the cell hint to move the mouse there.

![screenshot-of-mouse-grid](demo.jpg)

From there, if you want to do smaller movements, you can add some shortcuts to tools like [BetterTouchTool][4] to move N pixels in any direction. 

## Installation

Add this to your Hammerspoon config (`~/.hammerspoon/init.lua`) after placing the `positionMouseAtCell.lua` file in the `~/.hammerspoon/modules/` directory:

```
-- MOUSE GRID: Shows a grid on active screen and lets you type an address
-- to move the mouse cursor to that grid. 

    mouseGrid = require('modules/positionMouseAtCell')
    mouseGridHotKey = { modifiers = {'command', 'control', 'alt'}, key = '8' }

    mouseGrid.configure(mouseGridHotKey)
    hs.hotkey.bind(mouseGridHotKey.modifiers, mouseGridHotKey.key, nil, mouseGrid.run)
```
Pressing `⌘ + ⌃ + ⌥ + 8` activates the grid, but obviously you can change this hotkey when you configure the module.

[1]: https://www.hammerspoon.org/
[2]: https://www.hammerspoon.org/
[3]: https://github.com/nchudleigh/vimac
[4]: https://folivora.ai/
