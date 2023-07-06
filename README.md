### Fzf Combi Mode

![fzf-combi-mode-gif](https://raw.githubusercontent.com/wiki/RaviRahar/fzf-combi-mode/fzf-combi-mode.gif)

This plugin provides combi mode for [**FzfLua**](https://github.com/ibhagwan/fzf-lua). It just combines different
already existing modes and a new dir mode, making them work coherently.

- Combi mode combines 3 modes together:

  - dir: dir (custom)
  - grep: live_grep_native (default)
  - files: files (default)

### Install

Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug "RaviRahar/fzf-combi-mode"
Plug "ibhagwan/fzf-lua", {"branch": "main"}
Plug "junegunn/fzf", { "do": { -> fzf#install() } }
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "RaviRahar/fzf-combi-mode",
  requires = {
    {"ibhagwan/fzf-lua"},
    { "junegunn/fzf", run = "./install --bin" },
  }
}

```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "RaviRahar/fzf-combi-mode",
  dependencies = {
    {"ibhagwan/fzf-lua"},
    { "junegunn/fzf", run = "./install --bin" },
  }
}
```

### Quick-Start

```vim
:FzfCombiMode resume=true mode=dir
```

or

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>ff", ":FzfCombiMode resume=true<CR>", opts)
-- or
-- vim.keymap.set("n", "<leader>ff", function() require("fzf-combi-mode").mode_combi() end, opts)
```

Some default keybindings:

- \<C-f\> : cycle between modes
- \<BS\> : Act as normal backspace, but if query is empty then go back in path

### Configuration

```lua
-- These are defualts
-- Only provide settings you want to change
require("fzf-combi-mode").setup({
    default = "files",
    resume = true,
    keys = {
        grep_key = "ctrl-g",
        dir_key = "ctrl-i",
        files_key = "ctrl-b",
        cycle_key = "ctrl-f",
        parent_dir_key = "ctrl-h",
    }
})
```

- You can make two keybindings, one that always opens in current dir and another
  that resumes from where you left off. Both will work independently, i.e., state
  for keybinding with resume=false will not be saved

```lua
local opts = { noremap = true, silent = true }
-- keybinding that resumes
vim.keymap.set("n", "<leader>ff", function() require("fzf-combi-mode").mode_combi({ mode = "files" }) end, opts)
-- keybinding that do not resume
-- <leader>fh as in fzf_files here (in cwd), since it will not resume and will always open in cwd
vim.keymap.set("n", "<leader>fh", function() require("fzf-combi-mode").mode_combi({ resume = false, mode = "files" }) end, opts)
vim.keymap.set("n", "<leader>fg", function() require("fzf-combi-mode").mode_combi({ resume = false, mode = "grep" }) end, opts)
```
