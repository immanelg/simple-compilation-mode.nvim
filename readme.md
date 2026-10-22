# Simple Compilation Mode for Neovim
![image](https://github.com/user-attachments/assets/6e5996b0-67fe-4ff9-adbd-837cc9798553)

This plugin lets you create an interactive terminal buffer and repeatedly run a command in it.

## Usage
```lua
vim.pack.add({ "https://github.com/immanelg/simple-compilation-mode.nvim" })

-- if we already input a command, run it again.
-- if we didn't and it's our first time, input it and then run it.
vim.keymap.set({"n","t"}, "gs", function() CompileMode.compile_again() end)

-- input a command and run it
vim.keymap.set({"n","t"}, "gS", function() CompileMode.compile() end)

-- jump between errors
vim.keymap.set({"n","t"}, "<A-j>", function() CompileMode.jump_next() end)
vim.keymap.set({"n","t"}, "<A-k>", function() CompileMode.jump_prev() end)
vim.keymap.set({"n","t"}, "gzg", function() CompileMode.jump_first() end)
vim.keymap.set({"n","t"}, "gzG", function() CompileMode.jump_last() end)

 -- compilation buffer is a regular :terminal buffer.
vim.keymap.set("n", "gzb", function() CompileMode.switch_to_buffer() end)
```

Compilation buffer is a neovim `:terminal`, which is cleared before each run.

The buffer has these keybindings:
```
<cr>     go to location under cursor
r        compile again
<space>k floating preview
<c-c>    interrupt compilation
q        close buffer
```

## Comparisons
### `:make`
* Doesn't use a real terminal.
* Execution blocks UI.
* Command has to be set with `set makeprg..`.

### [ej-shafran/compile-mode.nvim](https://github.com/ej-shafran/compile-mode.nvim) (and Emacs)
Great plugin. This plugin is inspired by it.

It doesn't use a real terminal which is a tradeoff. It:
* Reimplements ANSI parsing
* Runs commands in non-interactive shell.
* Can't receive interactive input, etc.
* Can't let you run ad-hoc commands with immediate parsing of locations.
But our plugin:
* Can't know when a program have finished executing
* Can't reliably clear the terminal

### LSP
Real programmers don't use LSP.

