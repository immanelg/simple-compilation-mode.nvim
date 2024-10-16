local compile_command = nil

local buffer = nil
local chan = nil

local current_line = 1

-- -- this won't work because we need to call it after the compilation process exits, and we can't know when (without hacks?)
-- local locations = {}
-- local set_locations = function()
--     locations = {}
--     for i, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)) do
--         print(i, line)
--         local file, line, col, rest = line:match("^([%w_-%.]*):(%d+):(%d+):(.-)$")
--         if file and line and col then
--             table.insert(locations, {
--                 file = file,
--                 line = tonumber(line),
--                 column = tonumber(col),
--                 -- error = rest,
--             })
--             print("parsed", "file="..file, "line="..line, "col="..col)
--         end
--     end
--     print(vim.inspect(locations))
-- end

local hl_ns = vim.api.nvim_create_namespace("CompileHighlight")
vim.api.nvim_set_hl(hl_ns, "CompileLoc", { bg = "#404040", bold = true })
vim.api.nvim_set_hl_ns(hl_ns) 

local line_match_loc = function(line) 
    return line:match("^([%w/_-%.]*):(%d+):(%d+):(.-)$")
end

local jump_under_cursor = function()
    local loc = nil

    local buffer_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

    local i = vim.api.nvim_win_get_cursor(0)[1] -- nvim_win_get_cursor() is (1,0)-indexed
    -- local j = 0
    repeat
        local buffer_line = buffer_lines[i]
        if bufferline ~= "" then 
            local file, line, col, rest = line_match_loc(buffer_line)
            if file and line and col then
                loc = {file = file, line = tonumber(line), column = tonumber(col)}
                -- j = buffer_line:find(col)
                break
            end
        end
        i = i - 1
    until i == 0

    if loc ~= nil then
        vim.api.nvim_buf_clear_namespace(buffer, hl_ns, 0, -1)
        vim.api.nvim_buf_add_highlight(buffer, hl_ns, "CompileLoc", i-1 --[[0-indexed]], 0, -1)

        vim.cmd("edit "..loc.file)
    else
        print("no error here or above")
    end
end

local switch_to_buffer = function() 
    if not vim.api.nvim_buf_is_valid(buffer) then
        print("no compilation buffer")
    else 
        vim.api.nvim_win_set_buf(0, buffer)
    end
end

local ctrl_c = function() 
    vim.cmd.startinsert()
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
    vim.keymap.set("n", "r", function() ctrl_c() vim.schedule(function() CompileAgain() end) end, { buffer = buffer })
    -- vim.keymap.set("n", "<Cr>", function() vim.api.nvim_feedkeys("^gF", "i", true) end, { buffer = buffer })
    vim.keymap.set("n", "<Cr>", function() jump_under_cursor() end, { buffer = buffer })
end

local compile = function()
    assert(compile_command)
    maybe_init_buffer()
    vim.cmd.startinsert()
    vim.api.nvim_chan_send(chan, "clear\r")
    vim.api.nvim_chan_send(chan, compile_command.."\r")
    switch_to_buffer()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "i", true)
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, {3, 0})
    end)
    vim.api.nvim_buf_clear_namespace(buffer, hl_ns, 0, -1)

    -- vim.defer_fn(function() 
    --     set_locations()
    -- end, 1000)
end

local ask_compile_command = function(after) 
    vim.ui.input({prompt = 'compile command: ', default = compile_command or "make"}, function(input)
        if not input then return end
        compile_command = input
        after()
    end)
end

CompileAgain = function() 
    if not compile_command then
        ask_compile_command(compile)
    else
        compile()
    end
end

Compile = function() 
    ask_compile_command(compile)
end

CompileBuffer = function()
    switch_to_buffer()
end

NextError = nil

PrevError = nil

-- vim.keymap.set({"n", "t"}, "<F5>", CompileAgain)
-- vim.keymap.set({"n","t"}, "<Space><F5>", Compile)
-- vim.keymap.set("n", "<space>w", CompileBuffer)

-- vim.api.nvim_create_user_command("Compile", , {})
-- vim.api.nvim_create_user_command("CompileAgain", , {})
-- vim.api.nvim_create_user_command("CompileBuffer", , {})
-- vim.api.nvim_create_user_command("NextError", )
-- vim.api.nvim_create_user_command("PrevError", )
