# Dotfiles


## Install
### Linux/Mac
`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply brandonocasey; rm -rf ./bin/chezmoi && rmdir bin`

### Windows
`Set-ExecutionPolicy RemoteSigned -scope CurrentUser; (irm -useb https://get.chezmoi.io/ps1) | powershell -c -; bin/chezmoi init --apply brandonocasey; rm -r ./bin -fo`

fialoe
artn
# Priorities
* https://languagetool.org/download/ngram-data/
* remove no longer needed spelling lsp due to ltex
* evaluate
    * https://github.com/TheR1D/shell_gpt
    * https://aider.chat/docs/install.html
    * lazygit
    * forgit
    * lazydocker
    * https://github.com/dlvhdr/diffnav
    * https://proxyman.io/
* nvim extensions
    * https://github.com/akinsho/toggleterm.nvim
    * https://github.com/ggandor/leap.nvim
    * https://github.com/gbprod/cutlass.nvim
    * https://github.com/David-Kunz/treesitter-unit
    * Vim-expand-region
    * Refactoring https://github.com/ThePrimeagen/refactoring.nvim
    * https://github.com/mfussenegger/nvim-dap
    * https://github.com/rcarriga/nvim-dap-ui
    * https://github.com/sindrets/diffview.nvim

# Low Priorities
* fix regular vim

# Interesting Binaries
> install these if they ever get added to homebrew

* https://github.com/qarmin/czkawka
* https://github.com/reemus-dev/gitnr
* https://github.com/cezaraugusto/mklicense

# Issues
* switch from tealdear to navi once https://github.com/denisidoro/navi/issues/663
* remove vim-fetch if this ever gets added https://github.com/neovim/neovim/issues/1281
* check neovim releases for https://github.com/neovim/neovim/issues/7257
* IdentitiesOnly fails in ~/.ssh/config when doing npm install on git dependencies

# References
* https://github.com/johnalanwoods/maintained-modern-unix
* https://github.com/TaKO8Ki/awesome-alternatives-in-rust
