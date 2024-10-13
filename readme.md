# Simple Compilation Mode for Neovim

Work in progress, don't rely on it.

```lua
vim.keymap.set({"n","t"}, "<F5>", Recompile)
vim.keymap.set({"n","t"}, "<Space><F5>", Compile)
vim.keymap.set("n", "<space>w", CompileSwitchToBuffer)
```
