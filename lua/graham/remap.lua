
-- exit to netrw
vim.keymap.set("n", "<leader>pv", vim.cmd.Rex)

-- allow me to move the highlighted buffer up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- allow "J" (append below to current line) but keep cursor in same position instead of jumping to end 
vim.keymap.set("n", "J", "mzJ`z")

-- half page jump keep cursor in the middle of screen
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- search terms will appear in the middle of screen
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- preserve default register when pasting a word over highlighted text
vim.keymap.set("x", "<leader>p", "\"_dP")

-- delete to void register (preserve default yank register)
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")
vim.keymap.set("n", "<leader>c", "\"_c")
vim.keymap.set("v", "<leader>c", "\"_c")

-- leader y will yank into system clipboard
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- disable Ex mode, which allows scripting or command line stuff? idk.
vim.keymap.set("n", "Q", "<nop>")

-- format
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)

-- quick fix navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- find and replace current word in whole file
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- insert single character
vim.keymap.set("n", "<leader>r", function()
    vim.api.nvim_echo({{ "-- INSERT SINGLE --", "ModeMsg"}}, false, {})
    local char = vim.fn.getcharstr()

    vim.api.nvim_echo({}, false, {})  -- clear prompt
    local seq = vim.api.nvim_replace_termcodes("i" .. char .. "<ESC>", true, false, true)
    vim.api.nvim_feedkeys(seq, "n", false)

    vim.api.nvim_put({ vim.fn.nr2char(char) }, "c", false, true)
end, {desc = "insert one character" })

-- make current file executable with `chmod +x`
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- open current file in Windows Explorer (WSL)
vim.keymap.set("n", "<leader>pw", function()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
        vim.notify("No file path for current buffer", vim.log.levels.WARN)
        return
    end

    local win_path = vim.fn.systemlist({ "wslpath", "-w", file })[1]
    if not win_path or win_path == "" then
        vim.notify("Failed to convert path with wslpath", vim.log.levels.ERROR)
        return
    end

    vim.fn.jobstart({ "explorer.exe", "/select," .. win_path }, { detach = true })
end, { desc = "Reveal current file in Explorer" })

vim.keymap.set("n", "<leader>mc", "<cmd>SendSelectionToCodex<CR>", { desc = "Send location to CODEX" })
vim.keymap.set("v", "<leader>mc", ":SendSelectionToCodex<CR>", { desc = "Send selection to CODEX" })

-- disable arrow keys and mouse
vim.keymap.set("", "<up>", "<nop>", { noremap = true })
vim.keymap.set("", "<down>", "<nop>", { noremap = true })
vim.keymap.set("", "<left>", "<nop>", { noremap = true })
vim.keymap.set("", "<right>", "<nop>", { noremap = true })
vim.opt.mouse = ""
