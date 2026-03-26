vim.filetype.add({
    extension = { ino = "arduino" },
})

local sep = package.config:sub(1, 1)
local on_attach = require("graham.lsp.on_attach")

-- Check for required tools

local mason_bin = vim.fn.stdpath("data") .. sep .. "mason" .. sep .. "bin" .. sep
local als_bin = mason_bin .. "arduino-language-server.cmd"


if vim.fn.filereadable(als_bin) == 0 then
    als_bin = "arduino-launguage-server"
    if vim.fn.executable(als_bin) == 0 then
        vim.notify(
            "arduino-language-server not found. Install with: go install github.com/arduino/arduino-language-server@latest or with Mason",
            vim.log.levels.DEBUG)
        return {}
    end -- if executable
end     -- if readable

if vim.fn.executable("arduino-cli") == 0 then
    vim.notify("arduino-cli not found", vim.log.levels.DEBUG)
    return {}
end


local capabilities = require("cmp_nvim_lsp").default_capabilities()
local handle = io.popen('arduino-cli config --no-color dump --verbose')
local output = handle:read("*a")
handle:close()
local config_path = output:match('"Using config file: ([^\r\n]+)"')
config_path = config_path:gsub("\\\\", "\\")


-- Helper: does a directory contain ANY .ino?
local function contains_any_ino(dir)
    local found = vim.fs.find(
        function(name, _)
            return name:lower():sub(-4) == ".ino"
        end,
        { path = dir, limit = 1, type = "file" }
    )
    local result = found ~= nil and #found > 0
    if result then
        vim.notify("found *.ino files in " .. dir .. ": " .. found[1], vim.log.levels.DEBUG)
    end
    return result
end

local function arduino_root_dir(_, on_dir)
    local path = vim.fn.getcwd()
    if contains_any_ino(path) then
        vim.notify("Detected Arduino Project. Launching ALS...", vim.log.levels.INFO)
        -- Remove existing clangd instances.
        for _, client in pairs(vim.lsp.get_clients({ name = "clangd" })) do
            client.stop()
            -- vim.lsp.buf_detach_client(0, client.id)
        end --for

        -- remove future clangd instances.
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client.name == "arduino_language_server" then
                    return
                else
                    client.stop()
                    -- vim.lsp.buf_detach_client(0, client.id)
                end --if
            end,    --callback
        })
        on_dir(path)
    else
        return nil
    end             -- if
end                 -- arduino_root_dir

local c = {
    mason_bin .. "arduino-language-server.cmd",
    "--cli", "arduino-cli",
    "--clangd", mason_bin .. "clangd.cmd",
    "--cli-config", config_path,
    "--fqbn", "arduino:mbed_opta:opta",
    "--log", "--logpath", vim.fn.stdpath("data")
}


vim.api.nvim_create_user_command("ArduinoReindex",
    function()
        local result = vim.system({
                "arduino-cli", "compile",
                "--fqbn", "arduino:mbed_opta:opta",
                "--only-compilation-database",
            },
            { cwd = vim.loop.cwd() }):wait()
        if result ~= 0 then
            return vim.notify("arduino-cli compile failed:\n" .. result.stderr, vim.log.levels.ERROR)
        end -- if

        vim.schedule(
            function()
                vim.notify("Arduino compile DB refreshed. Restarting LSP")
                vim.cmd("LspRestart arduino_language_server")
            end)
    end,
    { desc = "Force recompile of arduino project and restart LSP" })

return {
    cmd = c,
    capabilities = capabilities,
    root_dir = arduino_root_dir,
    filetypes = { "arduino", "c", "cpp" },
    on_attach = on_attach,
}
