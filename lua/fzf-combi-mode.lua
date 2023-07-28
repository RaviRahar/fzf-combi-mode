-- opens in current directory, by default in "files"
--
-- traverse to parent directory with "backspace", "ctrl-h" (in all modes)
--
-- switch to files mode with files_key (current directory of fzf)
-- switch to grep mode with dir_key (current directory of dir)
-- switch to dir mode with grep_key, (current directory of fzf)
-- cycle between modes with cycle_key (current directory of fzf)
--
-- dir_mode: fuzzy find among directories, <CR> to go inside
--
-- resume from where you left off: same mode, same dir
-- or start a new session from current dir
--
--
local status, fzf_lua = pcall(require, 'fzf-lua')
if not status then
    print(fzf_lua)
    return
end
--
--
local M = {}
-- defaults are stored here
M.defaults = {
    -- used to check if plugin is resuming
    _is_resuming = false,
    _setup_done = false,
    _resume_data = {},

    resume = true,
    default = "files",

    grep_key = "ctrl-g",
    dir_key = "ctrl-i",
    files_key = "ctrl-k",
    cycle_key = "ctrl-f",
    parent_dir_key = "ctrl-h",
    dir_keys = {
        toggle_hidden_key = "ctrl-z",
        toggle_files_key = "ctrl-y",
        toggle_cycle_key = "ctrl-t",
        new_file_key = "ctrl-e",
        new_dir_key = "ctrl-w",
        rename_key = "ctrl-r",
        select_key = "ctrl-s",
        move_key = "ctrl-m",
        copy_key = "ctrl-c",
        delete_key = "ctrl-x",
        clear_selection_key = "ctrl-a",
        toggle_bookmark = "ctrl-b",
        clear_bookmarks_key = "ctrl-v",
    },
    grep_keys = {
        search_in_bookmarks_key = "ctrl-b",
    },
    files_keys = {
        search_in_bookmarks_key = "ctrl-b",
    },
}
-- user keys will be store in this table, check setup() function
M.userset = {}
-- used to override useropts by directly accessing through combi-mode
M.userset_override = {}
-- TODO:
-- Extend Dir Mode:
--  dir:
--      Toggle:
--          Hidden: ctrl-z
--          Files: ctrl-y
--          Cycle between both modes: ctrl-t
-- File Operations
--  dir
--     New: ctrl-n
--     Rename: ctrl-r
--     Select (Toggle): ctrl-s
--         Move: ctrl-m
--         Copy: ctrl-c
--         Delete: ctrl-d
--     Clear All Selections: ctrl-shift-s
-- Bookmark Directories and files:
--     dir:
--         Bookmark(Toggle): ctrl-b
--         Clear All Bookmarks : ctrl-shift-b
--     files,grep:
--         Search in bookmarked: ctrl-b

-- first check in userset if setting found
-- __newmethod allows values in defaults values to be changed directly
-- For ex: instead of M.defaults.resume=false we can use M.resume=false=false
setmetatable(M, { __index = M.userset, __newindex = M.defaults })
-- if not then check in defaults
setmetatable(M.userset, { __index = M.defaults })

M.cmd_get_dir = function(opts)
    local command = nil
    if vim.fn.executable("fd") == 1 then
        command = string.format("fd --type d --max-depth 1", opts.fd_opts)
    else
        if opts.find_global_opts == nil then opts.find_global_opts = "" end
        if opts.find_positional_opts == nil then opts.find_positional_opts = "" end
        command = string.format("find -L . -maxdepth 1 -mindepth 1 -type d -printf '%s\n'", "%P",
            opts.find_global_opts,
            opts.find_positional_opts)
    end
    return command
end

M.cmd_get_num_files = function(cwd, just_dirs)
    just_dirs = (just_dirs ~= nil) and just_dirs or false
    local cmd_num_files
    if just_dirs then
        cmd_num_files = string.format("find -L %s -maxdepth 1 -mindepth 1 -type d | wc -l", cwd)
    else
        cmd_num_files = string.format("find -L %s -maxdepth 1 -mindepth 1 | wc -l", cwd)
    end
    local num_files = tonumber(vim.fn.system(cmd_num_files))
    if num_files == nil then num_files = 0 end
    return num_files
end

M.set_legend = function(opts, legend)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = vim.fn.shellescape(string.format(":: %s", legend))
    return opts
end

M.remove_legend = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = nil
    return opts
end

M.edit_prompt_dir_mode = function(prompt, mode)
    -- prefix all mode_dir prompts with Dir:
    prompt = fzf_lua.path.HOME_to_tilde(prompt)
    if (#prompt >= 32) then
        prompt = fzf_lua.path.shorten(prompt)
    end
    if mode == "browser" then
        prompt = prompt:match("^%Browser: ") and prompt or "Browser: " .. prompt
    elseif mode == "files" then
        prompt = prompt:match("^%Files: ") and prompt or "Files: " .. prompt
    elseif mode == "creation" then
        prompt = prompt:match("^%New: ") and prompt or "New: " .. prompt
    elseif mode == "grep" then
        prompt = prompt:match("^%Regex: ") and prompt or "Regex: " .. prompt
    end
    prompt = prompt .. " > "
    return prompt
end

M.mode_files = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    opts.fn_transform = nil
    opts = M.remove_legend(opts)
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "files"
        M._resume_data = opts
    end
    opts.mode_previous = M.mode_files
    opts.actions = {
        [M.parent_dir_key] = { fn = function()
            local parent_dir_path = fzf_lua.path.parent(opts.cwd)
            opts.cwd = parent_dir_path
            M.mode_files(opts)
        end, exec_silent = true, field_index = false },
        ['default'] = { fn = function()
            if #fzf_lua.get_last_query() == 0 then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_files(opts)
            end
        end, field_index = false },
        ['return'] = fzf_lua.actions.file_edit_or_qf,
        [M.dir_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
        [M.grep_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
        [M.dir_keys.new_file_key] = { fn = function()
            opts.is_creation_dir = false
            M.mode_creation(opts)
        end, exec_silent = true, field_index = false },
        [M.dir_keys.new_dir_key] = { fn = function()
            opts.is_creation_dir = true
            M.mode_creation(opts)
        end, exec_silent = true, field_index = false },
    }
    fzf_lua.files(opts)
end
M.mode_grep = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    opts.exec_empty_query = true
    opts.fn_transform = nil
    opts = M.remove_legend(opts)
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "grep"
        M._resume_data = opts
    end
    opts.mode_previous = M.mode_grep
    opts.actions = {
        [M.parent_dir_key] = { fn = function()
            local parent_dir_path = fzf_lua.path.parent(opts.cwd)
            opts.cwd = parent_dir_path
            M.mode_grep(opts)
        end, exec_silent = true, field_index = false },
        ['default'] = { fn = function()
            if #fzf_lua.get_last_query() == 0 then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_grep(opts)
            end
        end, field_index = false },
        ['return'] = fzf_lua.actions.file_edit_or_qf,
        [M.dir_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
        [M.files_key] = { fn = function() M.mode_files(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
    }
    fzf_lua.live_grep_native(opts)
end

M.mode_creation = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    opts.prompt = M.edit_prompt_dir_mode(opts.cwd, "creation")
    opts.is_creation_dir = (opts.is_creation_dir ~= nil) and opts.is_creation_dir or false
    opts.actions = {
        [M.parent_dir_key] = { fn = function()
            local parent_dir_path = fzf_lua.path.parent(opts.cwd)
            opts.cwd = parent_dir_path
            M.mode_creation(opts)
        end, exec_silent = true, field_index = false },
        ['default'] = { fn = function()
            opts.is_creation_dir = nil
            opts.mode_previous(opts)
        end, field_index = false },
        ['return'] = { fn = function()
            local new_entity_name = fzf_lua.get_last_query()

            if new_entity_name ~= nil then
                if opts.is_creation_dir then
                    os.execute(string.format("mkdir -p %s", fzf_lua.path.join({ opts.cwd, new_entity_name })))
                else
                    os.execute(string.format(">> %s", fzf_lua.path.join({ opts.cwd, new_entity_name })))
                end
                opts.is_creation_dir = nil
                opts.mode_previous(opts)
            else
                M.mode_creation(opts)
            end
        end, field_index = true },
    }

    if opts.is_creation_dir then
        opts = M.set_legend(opts, "Enter Directory Name. Then Press Enter. Backspace to go to Browser.")
        fzf_lua.fzf_exec({}, opts)
    else
        opts = M.set_legend(opts, "Enter File Name. Then Press Enter. Backspace to go to Browser.")
        fzf_lua.fzf_exec({}, opts)
    end
end

M.mode_browser = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    -- opts.fn_transform = function(file_name)
    --     return fzf_lua.make_entry.file(file_name, { file_icons = true, color_icons = true })
    -- end
    opts.prompt = M.edit_prompt_dir_mode(opts.cwd, "browser")
    opts.dir_empty = false
    opts = M.remove_legend(opts)
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "dir"
        M._resume_data = opts
    end
    opts.mode_previous = M.mode_browser
    opts.actions = {
        [M.parent_dir_key] = { fn = function()
            local parent_dir_path = fzf_lua.path.parent(opts.cwd)
            opts.cwd = parent_dir_path
            M.mode_browser(opts)
        end, exec_silent = true, field_index = false },
        ['default'] = { fn = function()
            if #fzf_lua.get_last_query() == 0 then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_browser(opts)
            end
        end, field_index = false },
        ['return'] = { fn = function(selected)
            local selected_query = selected[1]
            if opts.dir_empty then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
            else
                local cur_dir_path = fzf_lua.path.entry_to_file(selected_query).path
                local next_dir_path = fzf_lua.path.join({ opts.cwd, cur_dir_path })
                opts.cwd = next_dir_path
            end
            M.mode_browser(opts)
        end, exec_silent = true },
        [M.files_key] = { fn = function()
            opts.prompt = nil
            M.mode_files(opts)
        end, exec_silent = true, field_index = false },
        [M.grep_key] = { fn = function()
            opts.prompt = nil
            M.mode_grep(opts)
        end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function()
            opts.prompt = nil
            M.mode_files(opts)
        end, exec_silent = true, field_index = false },
        [M.dir_keys.new_file_key] = { fn = function()
            opts.is_creation_dir = false
            M.mode_creation(opts)
        end, exec_silent = true, field_index = false },
        [M.dir_keys.new_dir_key] = { fn = function()
            opts.is_creation_dir = true
            M.mode_creation(opts)
        end, exec_silent = true, field_index = false },
    }

    if M.cmd_get_num_files(opts.cwd, true) > 0 then
        fzf_lua.fzf_exec(M.cmd_get_dir(opts), opts)
    else
        opts.dir_empty = true
        fzf_lua.fzf_exec({ "No Dirs Here. Go Back?" }, opts)
    end
end

M.mode_combi = function(opts)
    if not M._setup_done then
        M.setup()
    end

    opts = type(opts) == "table" and opts or {}

    -- for backspace functionality on empty query
    opts.keymap = { fzf = { ["backward-eof"] = "accept" } }

    if opts.mode == nil then
        opts.last_mode = M.default
    else
        opts.last_mode = opts.mode
    end

    if opts.resume == nil then
        opts.resume = M.resume
    end

    if opts.resume and M._is_resuming then
        opts = M._resume_data
    end

    M.userset_override = opts
    -- override options by directly accessing through combi-mode
    setmetatable(M.userset_override, { __index = fzf_lua.config.globals })
    if opts.last_mode == "files" then
        M.mode_files(M.userset_override)
    elseif opts.last_mode == "dir" then
        M.mode_browser(M.userset_override)
    elseif opts.last_mode == "grep" then
        M.mode_grep(M.userset_override)
    else
        print(string.format("fzf-combi-mode: mode %s does not exist", M.userset_override.last_mode))
    end
end

M.setup = function(opts)
    M.userset = type(opts) == "table" and opts or {}
    -- first check in userset if setting found
    -- __newmethod allows values in defaults values to be changed directly
    -- For ex: instead of M.defaults.resume=false we can use M.resume=false=false
    setmetatable(M, { __index = M.userset, __newindex = M.defaults })
    -- if not then check in defaults
    setmetatable(M.userset, { __index = M.defaults })
    M._setup_done = true
end

function M.load_command(...)
    local args = { ... }

    local user_opts = {}

    for _, arg in ipairs(args) do
        local param = vim.split(arg, "=")
        user_opts[param[1]] = param[2]
    end

    local opts = {}
    if user_opts.resume then
        if user_opts.resume:lower() == "true" then
            opts.resume = true
        elseif user_opts.resume:lower() == "false" then
            opts.resume = false
        end
    end
    if user_opts.mode then
        opts.mode = user_opts.mode
    end

    M.mode_combi(opts)
end

return M
