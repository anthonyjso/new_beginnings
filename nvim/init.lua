-- OPTIONS
-- tabs
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true


-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true


-- KEYMAPS
vim.g.mapleader = " "


-- PLUGINS
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
    {
        "neovim/nvim-lspconfig",
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
            "bash",
            "diff",
            "html",
            "javascript",
            "jsdoc",
            "json",
            "jsonc",
            "lua",
            "luadoc",
            "luap",
            "markdown",
            "markdown_inline",
            "python",
            "query",
            "regex",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "vimdoc",
            "xml",
            "yaml",
        },
    },
    {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
    {"nvim-telescope/telescope.nvim", tag = "0.1.6", dependencies = {"nvim-lua/plenary.nvim" }},
    {"junegunn/goyo.vim"},
    {"tpope/vim-fugitive"},
    {"Exafunction/codeium.vim"},
    {"rose-pine/neovim", name = "rose-pine"},
}
local opts = {}

require("lazy").setup(plugins, opts)

-- LSPs
local lspconfig = require('lspconfig')

lspconfig.bashls.setup{}

-- brew install lua-language-server
-- https://github.com/neovim/neovim/issues/21686#issuecomment-1522446128
lspconfig.lua_ls.setup {
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using
                -- (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {
                    'vim',
                    'require'
                },
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            },
        },
    },
}

--vscode-langservers-extracted
lspconfig.cssls.setup{}
lspconfig.html.setup{}
lspconfig.jsonls.setup{}
lspconfig.pyright.setup{}
lspconfig.ruff.setup{}

lspconfig.tsserver.setup{
  init_options = {
    plugins = {},
  },
  filetypes = {
    "javascript",
    "typescript",
  },
}


-- COLORSCHEME
vim.cmd("colorscheme rose-pine-moon")

-- telescope.nvim
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff' , builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fp', builtin.git_files, {})
vim.keymap.set('n', '<leader>c', builtin.commands, {})

-- trim trailing whitespace on save
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = {"*"},
    callback = function()
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
    end,
})

-- Function to open init.lua
function OpenInitLua()
  local config_path = vim.fn.stdpath('config') .. '/init.lua'
  vim.cmd('edit ' .. config_path)
end
vim.api.nvim_create_user_command('Config', OpenInitLua, {desc="Search available commands"})

-- Function to format the current buffer
function FormatCurrentBuffer()
  vim.lsp.buf.format({ async = true })
end

-- Map COMMAND+ALT+l to format the current buffer
vim.api.nvim_set_keymap(
  'n',
  '<leader>l',
  ':lua FormatCurrentBuffer()<CR>',
  { noremap = true, silent = true }
)
