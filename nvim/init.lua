vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:longest'
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set('n', '<leader>b', ':ShowBufferList<CR>')
-- vim.keymap.set('n', '<leader>do', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>d[', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>d]', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>df', vim.lsp.buf.format)
-- Toggle between solarized dark and light
vim.keymap.set("n", "<F5>", function()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
end, { desc = "Toggle Solarized background" })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    {
      'maxmx03/solarized.nvim',
      lazy = false,
      priority = 1000,
      ---@type solarized.config
      opts = {},
      config = function(_, opts)
        vim.o.termguicolors = true
        vim.o.background = 'dark'
        require('solarized').setup(opts)
        vim.cmd.colorscheme 'solarized'
      end,
    },
    {
        "nvim-treesitter/nvim-treesitter",
        branch = 'main',
        lazy = false,
        build = ":TSUpdate",
    },
    {
      "nvim-tree/nvim-tree.lua",
      version = "*",
      lazy = false,
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        require("nvim-tree").setup {}
      end,
    },
    { 'jlanzarotta/bufexplorer' },
    {
      "neovim/nvim-lspconfig", -- REQUIRED: for native Neovim LSP integration
      version = 'v2.5.0',
      lazy = false, -- REQUIRED: tell lazy.nvim to start this plugin at startup
      dependencies = {
        -- main one
        { "ms-jpq/coq_nvim", branch = "coq" },

        -- 9000+ Snippets
        { "ms-jpq/coq.artifacts", branch = "artifacts" },

        -- lua & third party sources -- See https://github.com/ms-jpq/coq.thirdparty
        -- Need to **configure separately**
        { 'ms-jpq/coq.thirdparty', branch = "3p" }
        -- - shell repl
        -- - nvim lua api
        -- - scientific calculator
        -- - comment banner
        -- - etc
      },
      init = function()
        vim.g.coq_settings = {
          auto_start = true, -- if you want to start COQ at startup
          -- Your COQ settings here
        }
      end,
      config = function()
        -- Your LSP settings here
      end,
    },
    { 'Vimjas/vim-python-pep8-indent' },
    { 'ludovicchabant/vim-gutentags' },
    { 'mfussenegger/nvim-dap' },
    {
        'mfussenegger/nvim-dap-python',
        config = function()
            require("dap-python").setup("python3")
        end,
    },
    {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        }
    },
    { 'stevearc/conform.nvim', opts = {} },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "solarized" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- ruff LSP: diagnostics only
require("lspconfig").ruff.setup({
  on_attach = function(client, bufnr)
    -- Disable LSP formatting so it doesn't conflict with ruff format
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  settings = {
    ruff = {
      lineLength = 88,
      lint = {
        select = { "E", "F", "W", "I" }, -- includes isort
        ignore = { "E501" },
      },
    },
  },
})

local uv = vim.uv or vim.loop

-- Walk upward to find a file
local function find_in_parents(startpath, target)
  local dir = startpath
  while dir do
    local candidate = dir .. "/" .. target
    local stat = uv.fs_stat(candidate)
    if stat then
      return candidate
    end

    local parent = dir:match("(.+)/[^/]+$")
    if parent == dir then
      return nil
    end
    dir = parent
  end
end

require("conform").setup({
  formatters_by_ft = {
    python = function(bufnr)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname == "" then
        return {}
      end

      local startpath = bufname:match("(.+)/[^/]+$")
      if not startpath then
        return {}
      end

      -- Look for pyproject.toml
      local pyproject = find_in_parents(startpath, "pyproject.toml")
      if not pyproject then
        return {}
      end

      -- Read file
      local fd = uv.fs_open(pyproject, "r", 438)
      if not fd then
        return {}
      end

      local stat = uv.fs_stat(pyproject)
      local data = uv.fs_read(fd, stat.size)
      uv.fs_close(fd)

      -- Check for the section
      if data and data:match("%[tool%.ruff%.lint%]") then
        return { "ruff_fix", "ruff_format" }
      end

      return {}
    end,
  },

  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = false,
  },
})

local telescope = require('telescope.builtin')
vim.keymap.set('n', '<C-D>', telescope.diagnostics, {noremap = true, silent = true})
