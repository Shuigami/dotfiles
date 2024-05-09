----------------------------- Variable -----------------------------
local Plug = vim.fn['plug#']
local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
local keyset = vim.keymap.set
local map = vim.keymap.set

------------------------------- Plug -------------------------------
vim.call('plug#begin', '/home/shui/.config/nvim/plugged')

-- Colorscheme
Plug 'navarasu/onedark.nvim'
Plug 'folke/tokyonight.nvim'
Plug('catppuccin/nvim', {as = 'catppuccin' })
Plug 'projekt0n/github-nvim-theme'

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

-- LSP & coc
Plug 'folke/lsp-colors.nvim'
Plug 'neoclide/coc.nvim'

-- Miscellaneous
Plug 'lewis6991/gitsigns.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'romgrk/barbar.nvim'
Plug 'elkowar/yuck.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'nvim-treesitter/nvim-treesitter'
Plug('nvimdev/dashboard-nvim', { event = 'VimEnter' })
Plug('iamcco/markdown-preview.nvim', { ['do'] = 'cd app && npx --yes yarn install' })

-- Telescope
Plug 'nvim-lua/plenary.nvim'
Plug('nvim-telescope/telescope.nvim', { branch = '0.1.5' })
Plug 'nvim-telescope/telescope-file-browser.nvim'

vim.call('plug#end')

------------------------------- Setup -------------------------------
-- Colorscheme
require('onedark').setup({
    style = 'cool',
})
require("catppuccin").setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = true, -- disables setting the background color.
})
require("tokyonight").setup({
    style = "night",
    transparent = true,
})
require('github-theme').setup({
    options = {
        transparent = true,       -- Disable setting background
    },
})

vim.cmd 'colorscheme github_dark_dimmed'

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Miscellaneous
require("autoclose").setup()
require("auto-save").setup()
require('feline').setup()
require('feline').winbar.setup()
require('colorizer').setup()
require('nvim-web-devicons').setup({
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
})
require('gitsigns').setup()

------------------------------- Default -------------------------------
vim.wo.colorcolumn = '80'

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftround = true
vim.opt.shiftwidth=2
vim.opt.softtabstop=2
vim.opt.tabstop=2

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

---------------------------------- Binding ---------------------------------
-- Buffer
map('n', '<C-k>', '<Cmd>BufferNext<CR>')
map('n', '<Tab>', '<Cmd>BufferNext<CR>')

map('n', '<C-j>',   '<Cmd>BufferPrevious<CR>')
map('n', '<S-Tab>', '<Cmd>BufferPrevious<CR>')

map('n', '<C-x>', '<Cmd>bd<CR>')
map('n', '<C-n>', '<Cmd>enew<CR>')

-- NerdTree
map('n', '<A-Tab>', '<Cmd>NERDTreeToggle<CR>')

map('n', '<C-c>e', ":Copilot enable<CR>")
map('n', '<C-c>d', ":Copilot disable<CR>")

-- Telescope
map('n', "fb", ":Telescope find_files<CR>", { noremap = true })
map('n', "ff", ":Telescope file_browser path=%:p:h select_buffer=true<CR>", { noremap = true })

-- CoC
keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)
keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

-- Miscellaneous
map('n', '<C-f><Space>', '<Cmd>noh<CR>')

----------------------------------- Other -----------------------------------
function Sad(line_nr, from, to, fname)
  vim.cmd(string.format("silent !sed -i '%ss/%s/%s/' %s", line_nr, from, to, fname))
end

-- Some servers have issues with backup files, see #649
vim.opt.backup = false
vim.opt.writebackup = false

-- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
-- delays and poor user experience
vim.opt.updatetime = 300

-- Always show the signcolumn, otherwise it would shift the text each time
-- diagnostics appeared/became resolved
vim.opt.signcolumn = "yes"

-- Autocomplete
function _G.check_back_space()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Some servers have issues with backup files, see #649
vim.opt.backup = false
vim.opt.writebackup = false

-- Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
-- delays and poor user experience
vim.opt.updatetime = 300

-- Always show the signcolumn, otherwise it would shift the text each time
-- diagnostics appeared/became resolved
vim.opt.signcolumn = "yes"

-- Autocomplete
function _G.check_back_space()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end
