{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      plugins = with pkgs.vimPlugins; [
        indent-blankline-nvim
        nerdtree
        vim-airline
        vim-airline-themes
        vim-colorschemes
        vim-nix
      ];
      extraConfig = ''
        set nocompatible            " disable compatibility to old-time vi
        set mouse=v                 " middle-click paste with
        set mouse=a                 " enable mouse click

        set encoding=utf-8
        set scrolloff=3
        set backspace=indent,eol,start

        set list
        "set listchars=tab:▸\ ,eol:¬,trail:·
        set listchars=tab:▸\ ,trail:·

        set termguicolors

        set hlsearch                " highlight search
        set incsearch               " incremental search
        set ignorecase              " case insensitive
        set smartcase
        set showmatch               " show matching

        set tabstop=2               " number of columns occupied by a tab
        set softtabstop=2           " see multiple spaces as tabstops so <BS> does the right thing
        set expandtab               " converts tabs to white space
        set shiftwidth=2            " width for autoindents
        set autoindent              " indent a new line the same amount as the line just typed

        " Enable hidden buffers with unsaved changes
        set hidden

        " remove trailing whitespace
        autocmd BufWritePre * :%s/\s\+$//e

        set ruler
        set cursorline
        set number
        set laststatus=2
        set cc=80                   " set an 80 column border for good coding style
        set cmdheight=1             " height of the command window on the bottom

        set wildmenu
        set wildmode=list:longest   " get bash-like tab completions

        filetype plugin indent on   " allow auto-indenting depending on file type
        syntax on                   " syntax highlighting
        set clipboard=unnamedplus   " using system clipboard
        filetype plugin on

        set ttyfast                 " Speed up scrolling in Vim

        set undofile
        silent !mkdir ~/.cache/vim > /dev/null 2>&1
        set backupdir=~/.cache/vim  " Directory to store backup files.

        set updatetime=150

        autocmd BufReadPost *
          \ if line("'\"") >= 1 && line("'\"") <= line("$") |
          \   exe "normal! g`\"" |
          \ endif

        " Suggestion from :checkhealth
        let g:loaded_perl_provider = 0

        " https://essais.co/better-folding-in-neovim/
        set foldmethod=indent
        set nofoldenable
        set foldlevel=99

        " Airline
        let g:airline_theme = 'bubblegum'
        let g:airline_powerline_fonts = 1
        let g:airline#extensions#tabline#enabled = 1
        let g:airline#extensions#tabline#left_sep = ' '
        let g:airline#extensions#tabline#left_alt_sep = '|'

        " unicode symbols
        if !exists('g:airline_symbols')
          let g:airline_symbols = {}
        endif

        let g:airline_left_sep = '»'
        let g:airline_right_sep = '«'
        let g:airline_symbols.linenr = '⮃'
        let g:airline_symbols.colnr = '⮀'
        let g:airline_symbols.branch = '⎇'
        let g:airline_symbols.paste = 'ρ'
        let g:airline_symbols.whitespace = 'Ξ'

        " Keybindings
        let mapleader = ","

        " F1 opens NERDTree
        nnoremap <F1> :NERDTreeToggle<CR>
        " Use double-<space> to save the file
        nnoremap <space><space> :w<cr>
        " Remap jj to Esc.
        inoremap jj <Esc>
        " Remove search highlighting
        nnoremap <leader><space> :noh<cr>
        " Tab jumps to matching bracket
        nnoremap <tab> %
        " Tab jumps to matching bracket
        vnoremap <tab> %

        " Show open buffers and ask for buffer number to jump to
        nnoremap gb :buffers<CR>:buffer<Space>

        " Move between buffers in normal mode
        nnoremap <C-PageDown>   :bprevious<CR>
        nnoremap <C-PageUp> :bnext<CR>
      '';
    };

    # Use Neovim as the editor for git commit messages
    programs.git.extraConfig.core.editor = "nvim";
    # Set Neovim as the default app for manual pages
    home.sessionVariables.MANPAGER = "nvim +Man!";
  };
}
