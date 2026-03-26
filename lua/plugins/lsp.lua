return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/nvim-cmp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "j-hui/fidget.nvim",
        },
        config = function()
            local cmp = require("cmp")
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities()
            )

            require("fidget").setup({})
            require("mason").setup({})
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                },
            })
            vim.lsp.config("lua_ls", {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = {
                                "vim",
                                "it",
                                "describe",
                                "before_each",
                                "after_each",
                            }
                        }
                    }
                }
            })

            vim.lsp.config("arduino_language_server", require("graham.lsp.arduino_ls"))
            -- local cmp_select = { behavior = cmp.SelectBehavior.Select }

            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),          -- manually trigger menu
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),

                    -- Smart Tab
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = "path" },
                }, {
                    { name = 'buffer' },
                })
            })
            vim.diagnostic.config({
                -- update_in_insert = true,
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = "always",
                    header = "",
                    prefix = "",
                },
            })
        end,
    },
    {
        "ray-x/lsp_signature.nvim",
        event = "InsertEnter",
        opts = {
            -- cfg options
        },
    },
}
