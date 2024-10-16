# Simple Compilation Mode for Neovim
![image](https://github.com/user-attachments/assets/6e5996b0-67fe-4ff9-adbd-837cc9798553)

This plugin lets you create a terminal buffer and repeatedly run a compilation command in it, like in Emacs Compilation Mode.

```lua
vim.keymap.set({"n","t"}, "<Space><F5>", Compile) -- set compilation command and compile
vim.keymap.set({"n","t"}, "<F5>", CompileAgain) -- recompile with previous command if it's set; otherwise set the command and compile
vim.keymap.set("n", "gw", CompileBuffer) -- open compilation buffer
```
Compilation buffer is a neovim `:terminal`, which is cleared before each run.

The buffer has these keybindings:
* `<c-c>`: interrupt compilation
* `<cr>`: go to location under cursor
* `q`: close buffer
