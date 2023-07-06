### Fzf Combi Mode

This plugin provides combi mode for **FzfLua**. It just combines different
already existing modes and a new dir mode, so they work coherently.

- Combi mode combines 3 modes together:

  - mode_grep: live_grep_native (default)
  - mode_files: files (default)
  - mode_dir: dir (custom)

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
  config = function()
    require("fzf-lua").setup({})
  end
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
  config = function()
    require("fzf-lua").setup({})
  end
}
```

### Quick-Start

```vim
:FzfCombiMode resume=true mode=mode_dir
```

or

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leadel>ff", function() require("fzf_combi_mode").mode_combi({ resume = true, mode = "mode_files" }) end, opts)
```

Some default keybindings:

- <C-f> : cycle between modes
- <BS> : Act as normal backspace, if query is empty then go back in path

### Configuration

For now there is no setup function. One will be added later. For now:

```lua
local fzf_lua_combi = require("fzf_combi_mode")

fzf_lua_combi.grep_key = "ctrl-g"
fzf_lua_combi.dir_key = "ctrl-i"
fzf_lua_combi.files_key = "ctrl-b"
fzf_lua_combi.cycle_key = "ctrl-f"
fzf_lua_combi.parent_dir_key = "ctrl-h"

local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leadel>ff", function() fzf_lua_combi.mode_combi({ resume = true, mode = "mode_files" }) end, opts)
```
