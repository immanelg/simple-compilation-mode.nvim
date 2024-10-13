# Simple Compilation Mode for Neovim

Work in progress, don't rely on it.

This plugin lets you create a terminal buffer and repeatedly run a compilation command in it, like in Emacs Compilation Mode.

```lua
vim.keymap.set({"n","t"}, "<Space><F5>", Compile) -- set compilation command and compile
vim.keymap.set({"n","t"}, "<F5>", Recompile) -- recompile with previous command if it's set; otherwise set the command and compile
vim.keymap.set("n", "<space>w", CompileSwitchToBuffer) -- open compilation buffer
```
Compilation buffer is a neovim `:terminal`, which is cleared before each run.

The buffer has these keybindings:
* `<c-c>`: interrupt compilation
* `<cr>`: go to location under cursor
* `q`: close buffer
