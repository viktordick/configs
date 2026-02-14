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
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- require("solarized").setup()
-- vim.cmd('colorscheme solarized')
-- require("nvim-web-devicons").setup()
-- require("nvim-tree").setup()

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

-- Required: Enable the language server
vim.lsp.config('ruff', {
  settings = {
    ruff = {
      config = "inline",  -- allow LSP settings to override project config
      line_length = 88,
      format = { enabled = false },
      select = { "E", "F", "W", "I" },
      ignore = { "E501" }, -- Black handles line length
    }
  }
})
vim.lsp.enable('ruff')

local function ruff_fix_all()
  local params = vim.lsp.util.make_range_params()
  params.context = {
    only = { "source.fixAll", "source.organizeImports" },
  }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, result, ctx)
    if err or not result then
      return
    end
    for _, action in ipairs(result) do
      if action.edit or action.command then
        -- Some servers return a Command, some an edit+command
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
        end
        if action.command then
          vim.lsp.buf.execute_command(action.command)
        end
      end
    end
  end)
end

local function ruff_fix()
  local params = vim.lsp.util.make_range_params()
  params.context = { only = { "source.fixAll", "source.organizeImports" } }

  vim.lsp.buf_request(0, "textDocument/codeAction", params, function(err, actions)
    if err or not actions then
      return
    end
    for _, action in ipairs(actions) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
      end
      if action.command then
        vim.lsp.buf.execute_command(action.command)
      end
    end
  end)
end


vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    -- ruff_fix()
    vim.lsp.buf.format()
  end,
})

require("conform").setup({
  formatters_by_ft = {
    python = { "black" },
  },
})

local telescope = require('telescope.builtin')
vim.keymap.set('n', '<C-D>', telescope.diagnostics, {noremap = true, silent = true})
