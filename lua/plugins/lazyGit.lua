return {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
        {
            "<leader>lg",
            function()
                if vim.env.TMUX and vim.env.TMUX ~= "" and vim.fn.executable("tmux") == 1 then
                    vim.fn.system({ "tmux", "select-window", "-t", "GIT" })
                    if vim.v.shell_error == 0 then
                        return
                    end
                end
                vim.cmd("LazyGit")
            end,
            desc = "LazyGit",
        },
    }
}
