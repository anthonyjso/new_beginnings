-- OPTIONS
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- KEYMAPS
-- Map leader to space
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--- Function to open init.lua
local function OpenInitLua()
  local config_path = vim.fn.stdpath("config") .. "/init.lua"
  vim.cmd("edit " .. config_path)
end
vim.api.nvim_create_user_command("Config", OpenInitLua, { desc = "Search available commands" })
vim.keymap.set("n", "<M-,>", "<cmd>Config<cr>")

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
vim.opt.runtimepath:prepend(lazypath)

local plugins = {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 50,
  },
  "folke/which-key.nvim",
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
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
  },
  "nvim-treesitter/nvim-treesitter-textobjects",
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- Library items can be absolute paths
            -- "~/projects/my-awesome-lib",
            -- Or relative, which means they will be resolved as a plugin
            -- "LazyVim",
            -- When relative, you can also provide a path to the library in the plugin dir
            "luvit-meta/library", -- see below
          },
        },
      },
    },
    config = function ()
      local lspconfig = require("lspconfig")
      local cmp_nvim_lsp = require("cmp_nvim_lsp")

      -- Add additional capabilities supported by nvim-cmp
      local capabilities = cmp_nvim_lsp.default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      -- bashls depends on shellcheck and shellfmt
      local servers = { "bashls", "cssls", "html", "jsonls", "pyright", "ruff" }
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup { capabilities = capabilities }
      end

      lspconfig.lua_ls.setup {
        capabilities = capabilities,
        settings = {
          diagnostics = {
            globals = { "vim" },
          },
          completion = {
            callSnippet = "Replace",
          }
        },
      }
      -- vscode-langservers-extracted
      lspconfig.tsserver.setup {
        capabilities = capabilities,
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
          vim.keymap.set("n", "<leader>vd", function () vim.diagnostic.open_float() end, lsp_opts)
          vim.keymap.set("n", "K", function () vim.lsp.buf.hover() end, lsp_opts)
          vim.keymap.set("n", "gK", function () vim.lsp.buf.signature_help() end, lsp_opts)
          vim.keymap.set("i", "<c-k>", function () vim.lsp.buf.signature_help() end, lsp_opts)
          vim.keymap.set("n", "<leader>ca", function () vim.lsp.buf.code_action() end, lsp_opts)
          vim.keymap.set("n", "<leader>l", function () vim.lsp.buf.format({ async = true }) end, lsp_opts)
          vim.keymap.set("n", "]]", function () vim.diagnostic.goto_next() end, lsp_opts)
          vim.keymap.set("n", "[[", function () vim.diagnostic.goto_prev() end, lsp_opts)
        end
      })
    end
  },
  {
    -- optional `vim.uv` typings
    "Bilal2453/luvit-meta",
    lazy = true
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lua",
      -- luasnip
      {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
      },
      "saadparwaiz1/cmp_luasnip", -- for autocompletion
      "onsails/lspkind.nvim",     -- vs-code like pictograms
    },
    opts = function (_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
    config = function ()
      local cmp = require("cmp")
      require("luasnip.loaders.from_vscode").lazy_load()
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      cmp.setup({
        window = {
          documentation = cmp.config.window.bordered(),
        },
        snippet = {
          expand = function (args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-p>"] = cmp.mapping.scroll_docs(-4),
          ["<C-n>"] = cmp.mapping.scroll_docs(4),
          ["<C-a>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function (fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function (fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" },
          { name = "nvim_lsp_signature_help" },
        }),
        formatting = {
          fields = { "menu", "abbr", "kind" },
          expandable_indicator = true,
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          })
        },
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" }
        }
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" }
        }),
      })
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      {
        "<leader>ff",
        "<cmd>Telescope find_files<cr>",
        desc = "Find files",
      },
      {
        "<leader>fg",
        "<cmd>Telescope live_grep<cr>",
        desc = "Live grep",
      },
      {
        "<leader>fb",
        "<cmd>Telescope buffers<cr>",
        desc = "Find buffers",
      },
      {
        "<leader>fh",
        "<cmd>Telescope help_tags<cr>",
        desc = "Help tags",
      },

    }
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "folke/zen-mode.nvim",
    config = function ()
      local zen_mode = require("zen-mode")
      vim.keymap.set("n", "<leader>zm",
        function ()
          zen_mode.toggle({ window = { backdrop = 0 }, })
        end)
    end
  },
}

local lazy = require("lazy")
lazy.setup(plugins, { colorscheme = { "rose-pine-moon" } })
vim.cmd("colorscheme rose-pine-moon")
