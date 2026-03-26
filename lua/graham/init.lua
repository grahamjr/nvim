-- Utility: check if an executable is on PATH
function has_exec(cmd)
    if vim.fn.executable(cmd) ~= 1 then
        vim.schedule(function()
            vim.api.nvim_err_writeln(
                cmd ..
                " not found in PATH. Some plugins will not work.\n"
            )
        end)
    end
end

has_exec('rg')

require("graham.set")
require("graham.remap")
require("graham.lazy")
require("graham.commands")
vim.opt.exrc = true
vim.opt.secure = true
