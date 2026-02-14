vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:longest'
vim.api.nvim_set_keymap("i", "jk", "<ESC>", {noremap = true})
vim.api.nvim_set_keymap('n', '<leader>b', ':ShowBufferList<CR>', {noremap=true})
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
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "solarized" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- Required: Enable the language server
vim.lsp.enable('pylsp')
