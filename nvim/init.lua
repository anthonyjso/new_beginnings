-- OPTIONS
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = false
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
  { "neovim/nvim-lspconfig" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "nvim-telescope/telescope.nvim",   tag = "0.1.6",      dependencies = { "nvim-lua/plenary.nvim" } },
  { "junegunn/goyo.vim" },
  { "tpope/vim-fugitive" },
  { "Exafunction/codeium.vim" },
  { "rose-pine/neovim",                name = "rose-pine" },
  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-path",
    },
    config = function ()
      local cmp = require("cmp")
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      cmp.setup({
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<leader><Tab>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "nvim_lsp_document_symbol" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end

  },
}

require("lazy").setup(plugins, {})

-- LSPs
local lspconfig = require("lspconfig")

-- Depends on shellcheck and shellfmt
lspconfig.bashls.setup {}

-- brew install lua-language-server
-- https://github.com/neovim/neovim/issues/21686#issuecomment-1522446128
lspconfig.lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {
          "vim",
          "require"
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

-- harper-ls
lspconfig.harper_ls.setup {
  settings = {
    ["harper-ls"] = {
      linters = {
        spell_check = true,
        spelled_numbers = false,
        an_a = true,
        sentence_capitalization = true,
        unclosed_quotes = true,
        wrong_quotes = false,
        long_sentences = true,
        repeated_words = true,
        spaces = true,
        matcher = true,
        correct_number_suffix = true,
        number_suffix_capitalization = true,
        userDictPath = "~/dict.txt"
      }
    }
  },
}


-- vscode-langservers-extracted
lspconfig.cssls.setup {}
lspconfig.html.setup {}
lspconfig.jsonls.setup {}
lspconfig.pyright.setup {}
lspconfig.ruff.setup {}
lspconfig.tsserver.setup {
  init_options = {
    plugins = {},
  },
  filetypes = {
    "javascript",
    "typescript",
  },
}

-- Configure keymaps and autocommands to use LSP features.
-- https://neovim.io/doc/user/lsp.html#lsp-quickstart
local AsoGroup = vim.api.nvim_create_augroup("AsoGroup", {})
vim.api.nvim_create_autocmd("LspAttach", {
  group = AsoGroup,
  callback = function (e)
    local lsp_opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", function () vim.lsp.buf.definition() end, lsp_opts)
    vim.keymap.set("n", "gD", function () vim.lsp.buf.declaration() end, lsp_opts)
    vim.keymap.set("n", "K", function () vim.lsp.buf.hover() end, lsp_opts)
    vim.keymap.set("n", "gK", function () vim.lsp.buf.signature_help() end, lsp_opts)
    vim.keymap.set("i", "<c-k>", function () vim.lsp.buf.signature_help() end, lsp_opts)
    vim.keymap.set("n", "<leader>ca", function () vim.lsp.buf.code_action() end, lsp_opts)
    vim.keymap.set("n", "gr", function () vim.lsp.buf.references() end, lsp_opts)
    vim.keymap.set("n", "<leader>l", function () vim.lsp.buf.format({ async = true }) end, lsp_opts)
    vim.keymap.set("n", "<leader>cR", function () vim.lsp.buf.rename() end, lsp_opts)
    vim.keymap.set("n", "]]", function () vim.diagnostic.goto_next() end, lsp_opts)
    vim.keymap.set("n", "[[", function () vim.diagnostic.goto_prev() end, lsp_opts)
    vim.keymap.set("n", "<a-n>", function () vim.diagnostic.goto_next() end, lsp_opts)
    vim.keymap.set("n", "<a-p>", function () vim.diagnostic.goto_prev() end, lsp_opts)
  end
})

-- telescope.nvim
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fp", builtin.git_files, {})
vim.keymap.set("n", "<leader>c", builtin.commands, {})
vim.keymap.set("n", "<M-space>", builtin.lsp_definitions, {})


-- trim trailing whitespace on save
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  callback = function ()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Function to open init.lua
function OpenInitLua()
  local config_path = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("edit " .. config_path)
end

vim.api.nvim_create_user_command("Config", OpenInitLua, { desc = "Search available commands" })


-- Codeium https://github.com/Exafunction/codeium.vim
-- Enable with CodeiumEnable if needed
vim.g.codeium_enabled = false

-- COLORSCHEME
vim.cmd("colorscheme rose-pine-moon")
