local Plug = vim.fn['plug#']
local map = vim.keymap.set

vim.call('plug#begin', '/home/shui/.config/nvim/plugged')

Plug 'navarasu/onedark.nvim'
Plug 'folke/tokyonight.nvim'

-- Autoclose
Plug 'm4xshen/autoclose.nvim'

-- Autosave
Plug 'Pocco81/auto-save.nvim'

-- NerdTree
Plug 'scrooloose/nerdtree'

-- Feline
Plug 'feline-nvim/feline.nvim'

-- Colorizer
Plug 'norcalli/nvim-colorizer.lua'

-- main one
Plug 'ms-jpq/coq_nvim'

-- 9000+ Snippets
Plug 'ms-jpq/coq.artifacts'

Plug 'ms-jpq/coq.thirdparty'

Plug 'lewis6991/gitsigns.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'

vim.call('plug#end')

-- require('onedark').load()
require("tokyonight").setup({
  style = "night",
  transparent = true,
})
vim.cmd[[colorscheme tokyonight]]
require("autoclose").setup()
require("auto-save").setup()
require('feline').setup()
require('feline').winbar.setup()
require('colorizer').setup()
vim.g.coq_settings = { auto_start = true }

vim.wo.colorcolumn = '80'

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftround = true
vim.opt.shiftwidth=4
vim.opt.softtabstop=4
vim.opt.tabstop=4

vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.cindent = true

vim.opt.mouse = 'a'

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.listchars = { eol='$', tab="»·", trail='·' }
vim.opt.list = true

vim.opt.ignorecase = true

vim.opt.spell = true

map('n', '<C-k>', '<Cmd>BufferNext<CR>')
map('n', '<Tab>', '<Cmd>BufferNext<CR>')
map('n', '<C-j>', '<Cmd>BufferPrevious<CR>')
map('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>')
map('n', '<C-f><Space>', '<Cmd>noh<CR>')
map('n', '<A-Tab>', '<Cmd>NERDTreeToggle<CR>')
map('n', '<C-x>', '<Cmd>bd<CR>')
map('n', '<C-n>', '<Cmd>enew<CR>')

require'nvim-web-devicons'.setup {
 -- your personnal icons can go here (to override)
 -- you can specify color or cterm_color instead of specifying both of them
 -- DevIcon will be appended to `name`
 override = {
  zsh = {
    icon = "",
    color = "#428850",
    cterm_color = "65",
    name = "Zsh"
  }
 };
 -- globally enable different highlight colors per icon (default to true)
 -- if set to false all icons will have the default icon's color
 color_icons = true;
 -- globally enable default icons (default to false)
 -- will get overriden by `get_icons` option
 default = true;
 -- globally enable "strict" selection of icons - icon will be looked up in
 -- different tables, first by filename, and if not found by extension; this
 -- prevents cases when file doesn't have any extension but still gets some icon
 -- because its name happened to match some extension (default to false)
 strict = true;
 -- same as `override` but specifically for overrides by filename
 -- takes effect when `strict` is true
 override_by_filename = {
  [".gitignore"] = {
    icon = "",
    color = "#f1502f",
    name = "Gitignore"
  }
 };
 -- same as `override` but specifically for overrides by extension
 -- takes effect when `strict` is true
 override_by_extension = {
  ["log"] = {
    icon = "",
    color = "#81e043",
    name = "Log"
  }
 };
}

function Sad(line_nr, from, to, fname)
  vim.cmd(string.format("silent !sed -i '%ss/%s/%s/' %s", line_nr, from, to, fname)) 
end
