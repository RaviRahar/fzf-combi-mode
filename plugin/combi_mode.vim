if !has('nvim-0.5')
    echohl Error
    echomsg "fzf-combi-mode is only available for Neovim versions 0.5 and above"
    echohl clear
    finish
endif
if exists("g:loaded_fzf_combi_mode")
    finish
endif
let g:loaded_fzf_combi_mode = 1

command! -nargs=* FzfCombiMode lua require('fzf_combi_mode').load_command(<f-args>)
