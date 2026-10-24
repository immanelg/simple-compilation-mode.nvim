local compile_command = nil

local buffer = nil
local chan = nil

local current_row_in_buffer = 0

local locations = {}

matchers = {
    -- number-indexed for deterministic looping order btw
    {
        -- jai
        regex  = "^(.-):(%d+),(%d*):(.*)$",
        loc = { file = 1, row = 2, column = 3, content = 4 }
    },
    {
        -- unix
        regex  = "^(.-):(%d+):(%d*):?(.*)$",
        loc = { file = 1, row = 2, column = 3, content = 4 },
    },
}

local function parse_line(row_in_buffer, line_string) 
    for _, matcher in ipairs(matchers) do
        local groups = { line_string:match(matcher.regex) }
        if #groups > 0 then
            local loc = {}
            for field, idx in pairs(matcher.loc) do
                loc[field] = groups[idx]
            end
            if loc.file then
                loc.row_in_buffer = row_in_buffer
                loc.row = tonumber(loc.row)
                loc.column = tonumber(loc.column or 1)
                return loc
            end
        end
    end
    return nil
end

local function create_popup(row, column, lines, ft)
    local popup_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(popup_buffer, 0, -1, false, lines)

    local BORDERS = 2
    local win = vim.api.nvim_open_win(popup_buffer, false, {
        relative = "editor",
        width = vim.o.columns-BORDERS,
        height = #lines,
        row = row,
        col = column,
        style = "minimal",
        border = "rounded",
    })
    vim.bo[popup_buffer].filetype = ft
    vim.bo[popup_buffer].bufhidden = "wipe"
    -- vim.bo[popup_buffer].modifiable = false

    vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = popup_buffer })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
end

local hl_ns = vim.api.nvim_create_namespace("CompileHighlight")
-- vim.api.nvim_set_hl(0, "CompileLoc", { bg = "#aaffff", fg = "#333333", bold = true })
vim.api.nvim_set_hl(0, "CompileCurrentLine", { link = "QuickFixLine", underline = true })
vim.api.nvim_set_hl(0, "CompileLine", { bold = true })

local function preview_under_cursor()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    for i = #locations, 1, -1 do
        local loc = locations[i]
        if loc.row_in_buffer <= row then
            -- open file under cursor, feed it into popup
            local buf = vim.fn.bufadd(loc.file)
            vim.fn.bufload(buf)
            local lines = {}
            for r = math.max(loc.row - 1, 1), loc.row + 1 do
                local text = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
                -- if text then table.insert(lines, string.format("%5d %s", r, text)) end
                if text then table.insert(lines, text) end
            end
            local pos = vim.fn.screenpos(0, row, 1)
            create_popup(pos.row, pos.col-1, lines, vim.filetype.match({ buf = buf }))
            return
        end
    end
end

local mark_current_line
local function jump(loc)
    if mark_current_line then vim.api.nvim_buf_del_extmark(buffer, hl_ns, mark_current_line) end
    mark_current_line = vim.api.nvim_buf_set_extmark(buffer, hl_ns, loc.row_in_buffer-1 --[[convert to 0 indexed]], 0, {
        end_row = loc.row_in_buffer-1,
        strict = false, end_col = -1,
        hl_group = "CompileCurrentLine",
    })

    if vim.fn.filereadable(loc.file) ~= 0 then
        vim.cmd("edit "..loc.file)
        vim.api.nvim_win_set_cursor(0, { loc.row or 1, math.max((loc.column or 1) - 1, 0) })
    else
        vim.notify("file not readable")
    end
end



local function jump_under_cursor()
    local row = vim.api.nvim_win_get_cursor(0)[1] -- NOTE: nvim_win_get_cursor() is (1,0)-indexed

    for i = #locations, 1, -1 do
        local loc = locations[i]
        if loc.row_in_buffer <= row then
            jump(loc)
            current_row_in_buffer = row
            return
        end
    end

    vim.notify("no error on this line or above. to add pattern, edit CompileMode.matchers")
end

local function jump_next()
    for i = 1, #locations, 1 do
        local loc = locations[i]
        if loc.row_in_buffer > current_row_in_buffer then
            current_row_in_buffer = loc.row_in_buffer
            jump(loc)
            return
        end
    end
    vim.notify("hit end")
end

local function jump_prev()
    for i = #locations, 1, -1 do
        local loc = locations[i]
        if loc.row_in_buffer < current_row_in_buffer then
            current_row_in_buffer = loc.row_in_buffer
            jump(loc)
            return
        end
    end
    vim.notify("hit start")
end
local function jump_first()
    local loc = locations[1]
    current_row_in_buffer = loc.row_in_buffer
    jump(loc)
end
local function jump_last()
    local loc = locations[#locations]
    current_row_in_buffer = loc.row_in_buffer
    jump(loc)
end
-- go to next error without jumping. or maybe jump_next(false)
local function next() end
local function prev() end

local function switch_to_buffer() 
    if not vim.api.nvim_buf_is_valid(buffer) then
        vim.notify("no compilation buffer")
    else
        vim.api.nvim_win_set_buf(0, buffer)
    end
end

local function interrupt_command()
    vim.cmd.startinsert()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, false, true), "i", true)
end

local function buffer_update_hook(lines)
    locations = {}
    for row_in_buffer, line in ipairs(lines) do
        local loc = parse_line(row_in_buffer, line)
        if loc and loc.file then 
            table.insert(locations, loc)
            vim.api.nvim_buf_set_extmark(buffer, hl_ns, loc.row_in_buffer-1, 0, {
                end_row = loc.row_in_buffer-1,
                strict = false, end_col = -1,
                hl_group = "CompileLine",
            })
            -- local pos = 1
            -- for _, field in ipairs({ FILE, ROW, COLUMN, CONTENT }) do
            --     local value = tostring(loc[field] or "")
            --     local s, e = line:find(value, pos, true)
            --     if s and value ~= "" then
            --         vim.api.nvim_buf_set_extmark(buffer, hl_ns, i - 1, s - 1, {
            --             end_col = e,
            --             hl_group = field_hl[field],
            --         })
            --         pos = e + 1
            --     end
            -- end
       end

    end
end

local compile_again -- fw declare for ensure_buffer_init

local function ensure_buffer_init()
    if buffer and vim.api.nvim_buf_is_valid(buffer) 
    then
        return
    end
    vim.cmd "term"
    chan = vim.bo.channel
    buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buffer, "compilation-term")
    vim.api.nvim_buf_attach(buffer, false, {
        on_lines = function(_, bufnr, changedtick, firstline, lastline, new_lastline, old_byte_size)
            vim.schedule(function()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lastline, false)
                buffer_update_hook(lines)
            end)
        end,
    })
    vim.keymap.set("n", "q",        "<cmd>bd!<cr>",       { buffer = buffer })
    vim.keymap.set("n", "<c-c>",    interrupt_command,    { buffer = buffer })
    vim.keymap.set("n", "r",        compile_again,        { buffer = buffer }) 
    vim.keymap.set("n", "<cr>",     jump_under_cursor,    { buffer = buffer })
    vim.keymap.set("n", "<space>k", preview_under_cursor, { buffer = buffer })
    -- TODO: explore...
    -- local win = vim.api.nvim_get_current_win()
    -- vim.api.nvim_win_set_buf(win, buffer)
    -- vim.wo[win].winfixheight = true
    -- vim.wo[win].winfixbuf = true
    -- vim.wo[win].number = false
    -- vim.wo[win].relativenumber = false
    -- vim.wo[win].signcolumn = "no"
    -- vim.wo[win].wrap = false
end

local function start_compilation()
    assert(compile_command)
    ensure_buffer_init()
    locations = {}
    current_row_in_buffer = 0
    vim.api.nvim_buf_clear_namespace(buffer, hl_ns, 0, -1)
    vim.cmd.startinsert()
    vim.api.nvim_chan_send(chan, "clear\r")
    -- vim.api.nvim_chan_send(chan, compile_command.."&& echo Compilation finished!".."\r")
    vim.api.nvim_chan_send(chan, compile_command.."\r")
    switch_to_buffer()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "i", true)
    vim.schedule(function()
        vim.api.nvim_win_set_cursor(0, {3, 0})
    end)
end

local ft_to_default_command
local function default_command()
    ft_to_default_command = ft_to_default_command or {
        jai = "jai first.jai ",
        rust = "cargo build ",
        go = "go vet . ",
        make = "make ",
        c = "make ",
        cpp = "make ",
        sh = "sh %",
        bash = "bash %",
        python = "uv run %",
        lua = "lua %",
        javascript = "npm run build ",
        typescript = "npm run build ",
        odin = "odin build . ",
    }
    return ft_to_default_command[vim.bo.filetype] or "rg --vimgrep "
end
local function ask_compile_command(after) 
    vim.ui.input({
        prompt = 'command: ',
        default = default_command(),
        completion = "shellcmdline",
    }, function(input)
        if not input then return end
        compile_command = input
        after()
    end)
end

local function compile() 
    ask_compile_command(start_compilation)
end

-- BUG: This doesn't interrupt the running compilation process.
-- And there's no reliable way to do it other than pressing Ctrl-C with nvim_feedkeys()
-- and hoping that the process will terminate fast enough for us to 
-- have time to send enter a command again.
compile_again = function()
    if compile_command
    then start_compilation()
    else ask_compile_command(start_compilation)
    end
end

CompileMode = {
    compile = compile,
    compile_again = compile_again,
    switch_to_buffer = switch_to_buffer,
    jump_next = jump_next,
    jump_prev = jump_prev,
    jump_first = jump_first,
    jump_last = jump_last,
}

-- vim.keymap.set({"n", "t"}, "<F5>", CompileAgain)
-- vim.keymap.set({"n","t"}, "<Space><F5>", Compile)
-- vim.keymap.set("n", "<space>w", CompileBuffer)

-- vim.api.nvim_create_user_command("Compile", , {})
-- vim.api.nvim_create_user_command("CompileAgain", , {})
-- vim.api.nvim_create_user_command("CompileBuffer", , {})
-- vim.api.nvim_create_user_command("NextError", )
-- vim.api.nvim_create_user_command("PrevError", )
