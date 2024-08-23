### Fzf Combi Mode

**Note:** Use fzf >= 0.53 or downgrade fzf-combi-mode to [this](https://github.com/RaviRahar/fzf-combi-mode/commit/26908068545eec03db8e80e2b2269e42bbe23e86) commit.

https://github.com/user-attachments/assets/93c4e8db-ec57-4d40-9033-4a31559f2369

This plugin provides combi mode for [**FzfLua**](https://github.com/ibhagwan/fzf-lua). It just combines different
already existing modes and a new browser mode, making them work coherently.

- Combi mode combines 3 modes together:

  - browser: browser (custom)
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
:FzfCombiMode res=true mode=browser
```

or

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>ff", ":FzfCombiMode res=true<CR>", opts)
-- or
-- vim.keymap.set("n", "<leader>ff", function() require("fzf-combi-mode").mode_combi() end, opts)
```

Some default keybindings:

- \<C-f\> : cycle between modes
- \<BS\> : Act as normal backspace, but if query is empty then go back in path
- \<C-t\> : cycle in submodes of browser mode (toggles files or hidden, by
  default only non-hidden directories are shown)

### Configuration

```lua
-- These are defualts
-- Only provide settings you want to change
require("fzf-combi-mode").setup({
    default = "files",
    res = true,
    keys = {
        grep_key = "ctrl-g",
        browser_key = "ctrl-i",
        files_key = "ctrl-b",
        cycle_key = "ctrl-f",
        parent_dir_key = "ctrl-h",
        reset_dir_key = "ctrl-p",
        browser_keys = {
            toggle_hidden_key = "ctrl-z",
            toggle_files_key = "ctrl-y",
            toggle_cycle_key = "ctrl-t",
            goto_path_key = "ctrl-l",
            new_file_key = "ctrl-q",
            new_dir_key = "ctrl-e",
            delete_key = "ctrl-x",
        }
    }
})
```

- You can make two keybindings, one that always opens in current dir and another
  that resumes from where you left off. Both will work independently, i.e., state
  for keybinding with res=false will not be saved

```lua
local opts = { noremap = true, silent = true }
-- keybinding that resumes
vim.keymap.set("n", "<leader>ff", function() require("fzf-combi-mode").mode_combi({ mode = "files" }) end, opts)
-- keybinding that do not resume
-- <leader>fh as in fzf_files here (in cwd), since it will not resume and will always open in cwd
vim.keymap.set("n", "<leader>fh", function() require("fzf-combi-mode").mode_combi({ res = false, mode = "files" }) end, opts)
vim.keymap.set("n", "<leader>fg", function() require("fzf-combi-mode").mode_combi({ res = false, mode = "grep" }) end, opts)
```
