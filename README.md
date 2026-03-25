# Neovim Config

Personal Neovim configuration built around `lazy.nvim`, LSP support, Telescope, Treesitter, and a tmux-based development session launcher.

## Dependencies

### Required

- `nvim` 0.11+ (this config uses `vim.lsp.config`)
- `git` (used to bootstrap `lazy.nvim`)
- `rg` / `ripgrep` (checked on startup and used by Telescope)

### Required for the tmux workflow

- `tmux`
- `lazygit` for the `GIT` tmux window created by the launcher

### Optional but used by specific features

- `tree-sitter` CLI if you want Treesitter parser auto-install to work reliably
- `wslpath` and `explorer.exe` for `<leader>pw` in WSL
- `codex` if you want the launcher to create a `CODEX` window automatically
- Language servers installed through Mason or on your `PATH`
  - `lua_ls` is configured via Mason
  - `arduino_language_server` is configured from [`lua/graham/lsp/arduino_ls.lua`](/home/linuxbox/.config/nvim/lua/graham/lsp/arduino_ls.lua)

## Install

Clone or copy this repo to:

```bash
~/.config/nvim
```

Then start Neovim:

```bash
nvim
```

On first launch, `lazy.nvim` will bootstrap itself and install the configured plugins.

## Plugin Set

This config currently loads:

- `lazy.nvim` for plugin management
- `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`, `nvim-cmp`, `LuaSnip`, and `fidget.nvim` for LSP and completion
- `nvim-treesitter` for syntax parsing/highlighting
- `telescope.nvim` for file and text search
- `lazygit.nvim` for Git UI
- `csvview.nvim` for CSV editing
- `nvim-dev-container`
- `rose-pine` colorscheme

## Tmux Session Launcher

The main tmux entry point is [`scripts/launch_dev_env.sh`](/home/linuxbox/.config/nvim/scripts/launch_dev_env.sh). It creates or attaches to a tmux session set up for development in the current project.

### What it creates

By default, the launcher creates a tmux session named `dev` with these windows:

- `EDITOR`: runs `nvim . --listen /tmp/nvim-<session>.sock`
- `GIT`: runs `lazygit` with [`scripts/tmux_session_config.yml`](/home/linuxbox/.config/nvim/scripts/tmux_session_config.yml)
- `BUILD`: opens a shell in the project directory
- `CODEX`: starts `codex` if the `codex` executable is available

If the session already exists, the script attaches to it. If you pass restart mode, it kills the old session and recreates it.

### Usage

Run it from the project you want to work in:

```bash
./scripts/launch_dev_env.sh
```

Common options:

```bash
./scripts/launch_dev_env.sh -s mysession
./scripts/launch_dev_env.sh -d /path/to/project
./scripts/launch_dev_env.sh -v "source .venv/bin/activate"
./scripts/launch_dev_env.sh -r
```

Flags:

- `-s <session_name>`: tmux session name, default `dev`
- `-d <project_dir>`: project directory to open, default current directory
- `-v <venv_cmd>`: command to activate an environment before windows are created
- `-r` or `-restart`: kill and recreate the session if it already exists

### How the environment is shared

The launcher sets session-level environment variables so each window starts with the same base setup:

- `PROJECT_DIR`
- `SCRIPT_DIR`
- `NVIM_SOCK`
- `PATH` with `PROJECT_DIR/.scripts` and this repo’s `scripts/` directory prepended
- `TMPDIR` set to `~/tmp/tmux-<session>`

If you pass `-v`, the script runs that activation command once in a bootstrap window, captures the resulting environment, and reuses it for the session. In practice, that means a Python virtualenv can be activated across `EDITOR`, `GIT`, `BUILD`, and `CODEX` without repeating the setup manually.

### Example workflow

From a project root:

```bash
~/.config/nvim/scripts/launch_dev_env.sh -v "source .venv/bin/activate"
```

This will:

1. Create or attach to a tmux session named `dev`
2. Start Neovim in the `EDITOR` window
3. Start LazyGit in the `GIT` window
4. Leave a shell ready in `BUILD`
5. Start `codex` in `CODEX` if `codex` is installed

### Neovim tmux integration

Inside Neovim, this config also provides `:SendSelectionToCodex` and `<leader>mc`.

That command:

- requires Neovim to be running inside tmux
- requires a tmux window named `CODEX`
- sends `relative/path:line` or `relative/path:start-end`
- switches tmux to the `CODEX` window after pasting

`<leader>lg` similarly prefers switching to a tmux window named `GIT`, and falls back to opening `LazyGit` inside Neovim if that window does not exist.
