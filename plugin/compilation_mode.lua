local compile_command = nil

local buffer = nil
local chan = nil

local switch_to_buffer = function() 
    if not vim.api.nvim_buf_is_valid(buffer) then
        print("no compilation buffer")
    else 
        vim.api.nvim_win_set_buf(0, buffer)
    end
end

local ctrl_c = function() 
    vim.cmd "startinsert"
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), "i", true)
end

local maybe_init_buffer = function()
    if buffer and vim.api.nvim_buf_is_valid(buffer) then
        return
    end
    vim.cmd "term"
    chan = vim.bo.channel
    buffer = vim.api.nvim_get_current_buf()
    vim.keymap.set("n", "q", "<cmd>bd!<cr>", { buffer = buffer })
    vim.keymap.set("n", "<C-c>", function() ctrl_c() end, { buffer = buffer })
    -- vim.keymap.set("n", "r", function() ctrl_c() Recompile() end, { buffer = buffer })
    vim.keymap.set("n", "<Cr>", function() vim.api.nvim_feedkeys("^gF", "i", true) end, { buffer = buffer })
end

local compile = function()
    assert(compile_command)
    maybe_init_buffer()
    vim.api.nvim_chan_send(chan, "clear;printf \"compilation started at "..os.date("%Y-%m-%d %H:%M:%S").."\n\"\r")
    vim.api.nvim_chan_send(chan, compile_command.."\r")
    switch_to_buffer()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "i", true)
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, {3, 0})
    end)
end

local ask_compile_command = function(after) 
    vim.ui.input({prompt = 'set compile command: ', default = compile_command or "make"}, function(input)
        if not input then return end
        compile_command = input
        after()
    end)
end

Recompile = function() 
    if not compile_command then
        ask_compile_command(compile)
    else
        compile()
    end
end

Compile = function() 
    ask_compile_command(compile)
end

CompilationBuffer = function()
    switch_to_buffer()
end

NextError = nil

PrevError = nil

vim.keymap.set({"n", "t"}, "<F5>", Recompile)
vim.keymap.set({"n","t"}, "<Space><F5>", Compile)
vim.keymap.set("n", "<space>w", CompilationBuffer)

-- vim.api.nvim_create_user_command("Compile", , {})
-- vim.api.nvim_create_user_command("Recompile", , {})
-- vim.api.nvim_create_user_command("CompilationBuffer", , {})
-- vim.api.nvim_create_user_command("NextError", )
-- vim.api.nvim_create_user_command("PrevError", )
