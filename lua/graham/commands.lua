
-- Global
vim.api.nvim_create_user_command(
    "AddSheBang",
    function (opts) 
        vim.api.nvim_buf_set_lines(0, 0, 0, false, 
            {"#!" .. vim.fn.exepath(opts.fargs[1])})
    end,
    {nargs = 1, desc = "Adds #!... for the specified executable." }
)

vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('highligh_yank', {clear = true}),
    desc = "Highlight selection on yank",
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch', 
            timeout = 500,
        })
    end, -- callback
})

local function send_to_codex(opts)
    if vim.env.TMUX == nil or vim.env.TMUX == "" then
        vim.notify("Not running inside tmux", vim.log.levels.WARN)
        return
    end

    if vim.fn.executable("tmux") ~= 1 then
        vim.notify("tmux is not available", vim.log.levels.ERROR)
        return
    end

    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("Current buffer has no file path", vim.log.levels.WARN)
        return
    end

    local line_start
    local line_end
    if opts.range > 0 then
        line_start = vim.fn.getpos("'<")[2]
        line_end = vim.fn.getpos("'>")[2]
    else
        line_start = vim.api.nvim_win_get_cursor(0)[1]
        line_end = line_start
    end

    if line_start > line_end then
        line_start, line_end = line_end, line_start
    end

    local relative_file = vim.fn.fnamemodify(file, ":.")
    local location = relative_file .. ":" .. tostring(line_start)
    if line_end ~= line_start then
        location = location .. "-" .. tostring(line_end)
    end

    local paste_text = location .. "\n"
    local load_result = vim.fn.system({ "tmux", "load-buffer", "-" }, paste_text)
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to stage location for CODEX: " .. load_result, vim.log.levels.ERROR)
        return
    end

    vim.fn.system({ "tmux", "paste-buffer", "-t", "CODEX" })
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to paste location into CODEX", vim.log.levels.ERROR)
        return
    end

    vim.fn.system({ "tmux", "select-window", "-t", "CODEX" })
    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to switch to CODEX window", vim.log.levels.ERROR)
    end
end

vim.api.nvim_create_user_command(
    "SendSelectionToCodex",
    send_to_codex,
    { range = true, desc = "Send current file and selected lines to the CODEX tmux window" }
)
