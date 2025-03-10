-- opens in current directory, by default in "files"
--
-- traverse to parent directory with "backspace", "ctrl-h" (in all modes)
--
-- switch to files mode with files_key (current directory of fzf)
-- switch to grep mode with grep_key (current directory of fzf)
-- switch to browser mode with browser_key, (current directory of fzf)
-- cycle between modes with cycle_key (current directory of fzf)
--
-- browser_mode: fuzzy find among directories, <CR> to go inside or open a file
--
-- resume from where you left off: same mode, same dir
-- or start a new session from current dir
--
--

local CombiMode = require('combimode')

function CombiMode.load_command(...)
    local args = { ... }

    local user_opts = {}

    for _, arg in ipairs(args) do
        local param = vim.split(arg, "=")
        user_opts[param[1]] = param[2]
    end

    local opts = {}
    if user_opts.res then
        if user_opts.res:lower() == "true" then
            opts.res = true
        elseif user_opts.res:lower() == "false" then
            opts.res = false
        end
    end

    -- allow for change of mode to new mode supplied from last_mode on res
    if user_opts.change then
        if user_opts.change:lower() == "true" then
            opts.change = true
        elseif user_opts.change:lower() == "false" then
            opts.change = false
        end
    end

    if user_opts.mode then
        opts.mode = user_opts.mode:lower()
    end

    CombiMode.run(opts)
end

return CombiMode 
