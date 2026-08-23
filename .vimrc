" General
let mapleader="\<SPACE>" " Map the leader key to SPC.
set hidden               " This allows buffers to be hidden if you've modified a buffer.
set undofile             " Keep undo history between sessions

" Temporary files
" Vim's default 'directory' and 'backupdir' both start with '.', which drops
" .foo.txt.swp beside foo.txt and makes it surface in git status. Park all
" three kinds of scratch file under ~/.vim instead. The trailing '//' encodes
" the edited file's full path into the name, so same-named files in different
" directories don't collide on one swapfile.
set directory=~/.vim/swap//
set backupdir=~/.vim/backup//
set undodir=~/.vim/undo//

" Vim will NOT create these, and a missing dir fails quietly.
" 0700 because swap and undo files hold file contents verbatim.
for s:dir in [&directory, &backupdir, &undodir]
  let s:path = expand(substitute(s:dir, '/\+$', '', ''))
  if !isdirectory(s:path)
    call mkdir(s:path, 'p', 0700)
  endif
endfor

" Search
set hlsearch             " Highlight search results.
set ignorecase           " Make searching case insensitive
set smartcase            " ... unless the query contain uppercase letters.
set incsearch            " Incremental search.

" Formatting
set list                 " Display invisible chars
set showcmd              " Show (partial) command in status line.
set showmatch            " Show matching brackets.
set showmode             " Show current mode.
set ruler                " Show the line and column numbers of the cursor.
set number               " Show the line numbers on the left side.
set colorcolumn=80

set smarttab             " Auto insert appropriate number of tabs or spaces
set shiftwidth=2         " Indentation amount for < and > commands.
set softtabstop=2
set tabstop=2
set expandtab            " Tabs are spaces, use Ctrl+v Tab to insert tab
set autoindent
set copyindent
set preserveindent

set modeline             " Check beginning and end of file for modelines.
set nojoinspaces         " Prevents inserting two spaces after punctuation on a join (J)

" More natural splits
set splitbelow           " Horizontal split below current.
set splitright           " Vertical split to right of current.

set scrolloff=3          " Show next 3 lines while scrolling.
set nostartofline        " Do not jump to first character with page commands.

" Diff options
set diffopt+=iwhite      " Ignore changes in amount of white space.

" Keybindings

" Map ; to :
nnoremap ; :
" Save file
nnoremap <leader>w :w<CR>
" Copy and paste from system clipboard
vmap <leader>yy "+y
vmap <leader>yd "+d
nmap <leader>yp "+p
nmap <leader>yP "+P
vmap <leader>yp "+p
vmap <leader>yP "+P
" Indent as many times as you want in visual mode without losing focus
vnoremap < <gv
vnoremap > >gv

" Close current buffer without closing a window
nmap <leader>bq :bp <BAR> bd #<CR>

" Remove trailing spaces before saving text files
" http://vim.wikia.com/wiki/Remove_trailing_spaces
autocmd BufWritePre * :call StripTrailingWhitespace()
function! StripTrailingWhitespace()
  if !&binary && &filetype != 'diff'
    normal mz
    normal Hmy
    if &filetype == 'mail'
      " Preserve space after e-mail signature separator
      %s/\(^--\)\@<!\s\+$//e
    else
      %s/\s\+$//e
    endif
    normal 'yz<Enter>
    normal `z
  endif
endfunction

" Relative numbering
function! NumberToggle()
  if(&relativenumber == 1)
    set nornu
    set number
  else
    set rnu
  endif
endfunction

" Toggle between normal and relative numbering.
nnoremap <leader>r :call NumberToggle()<cr>

" True color (24-bit). Ghostty/iTerm2/WezTerm support it; Apple Terminal.app does not.
" Must be set BEFORE plugins.vim runs `colorscheme nord`, so Nord uses its
" intended brighter comment color (#616E88) instead of the dim 256-color fallback.
if has('termguicolors') && $TERM_PROGRAM !=# 'Apple_Terminal'
  " Make truecolor work through tmux/screen as well.
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

source ~/.vim/plugins.vim
