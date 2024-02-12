# Dotfiles

## Step 1: Setup ssh key
1. Run `ssh-keygen` and add the key to your github account

## Install Mac/Linux
*CHANGE THE SSH KEY LOCATION ACCORDINGLY*
```bash
curl --user brandonocasey https://raw.githubusercontent.com/brandonocasey/dotfiles/main/install/install.bash | bash
```
## Install Windows
*CHANGE THE SSH KEY LOCATION ACCORDINGLY*
```ps1
mkdir -p ~/.local/share && \
git clone git@github.com:brandonocasey/dotfiles.git ~/.local/share/chezmoi && \
~/.local/share/chezmoi/install/install.ps1
```

# Priorities
* setup delta
* https://github.com/junegunn/fzf/blob/master/ADVANCED.md#switching-between-ripgrep-mode-and-fzf-mode-using-a-single-key-binding
* evaluate
    * https://github.com/TheR1D/shell_gpt
    * https://aider.chat/docs/install.html
    * lazygit
    * forgit
    * lazydocker
    * https://formulae.brew.sh/formula/felinks
* ssh key stuff
    * Can we setup https://superuser.com/questions/232373/how-to-tell-git-which-private-key-to-use/1664624#1664624
    * https://usercomp.com/news/1044072/using-ssh-agent-on-mac
    * Fish ssh agent
* nvim extensions
    * https://github.com/akinsho/toggleterm.nvim
    * https://github.com/ggandor/leap.nvim
    * https://github.com/gbprod/cutlass.nvim
    * Copilot or chatgpt
    * https://github.com/iamcco/markdown-preview.
    * https://github.com/David-Kunz/treesitter-unit
    * Vim-expand-region 
    * Refactoring https://github.com/ThePrimeagen/refactoring.nvim
    * https://github.com/mfussenegger/nvim-dap
    * https://github.com/rcarriga/nvim-dap-ui
    * https://github.com/sindrets/diffview.nvim
* get a global find-replace keybind

# Low Priorities
* fix regular vim

# Interesting Binaries
> I dont install these as they are not on homebrew

* https://github.com/qarmin/czkawka
* https://github.com/facebookincubator/fastmod
* https://github.com/marcosnils/bin/
* https://github.com/reemus-dev/gitnr
* https://github.com/cezaraugusto/mklicense

# Issues
* switch from tealdear to navi once https://github.com/denisidoro/navi/issues/663 is resolved
* remove vim-fetch if this ever gets added https://github.com/neovim/neovim/issues/1281
* check neovim releases for https://github.com/neovim/neovim/issues/7257

# References
https://github.com/johnalanwoods/maintained-modern-unix
https://github.com/TaKO8Ki/awesome-alternatives-in-rust
