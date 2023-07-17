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
    dir_keys = {},
    grep_keys = {},
    files_keys = {},
}
-- user keys will be store in this table, check setup() function
M.userset = {}
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

M.edit_prompt_dir_mode = function(prompt)
    -- prefix all mode_dir prompts with Dir:
    prompt = fzf_lua.path.HOME_to_tilde(prompt)
    prompt = fzf_lua.path.shorten(prompt)
    return prompt:match("^%Dir: ") and prompt or "Dir: " .. prompt
end

M.mode_files = function(opts)
    opts = opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    opts.fn_transform = nil
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "files"
        M._resume_data = opts
    end
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
        [M.dir_key] = { fn = function() M.mode_dir(opts) end, exec_silent = true, field_index = false },
        [M.grep_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
    }
    fzf_lua.files(opts)
end
M.mode_grep = function(opts)
    opts = opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    opts.exec_empty_query = true
    opts.fn_transform = nil
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "grep"
        M._resume_data = opts
    end
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
        [M.dir_key] = { fn = function() M.mode_dir(opts) end, exec_silent = true, field_index = false },
        [M.files_key] = { fn = function() M.mode_files(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_dir(opts) end, exec_silent = true, field_index = false },
    }
    fzf_lua.live_grep_native(opts)
end
M.mode_dir = function(opts)
    opts = opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()
    -- opts.fn_transform = function(file_name)
    --     return fzf_lua.make_entry.file(file_name, { file_icons = true, color_icons = true })
    -- end
    opts.prompt = M.edit_prompt_dir_mode(opts.cwd)
    opts.dir_empty = false
    if opts.resume == true then
        M._is_resuming = true
        opts.last_mode = "dir"
        M._resume_data = opts
    end
    opts.actions = {
        [M.parent_dir_key] = { fn = function()
            local parent_dir_path = fzf_lua.path.parent(opts.cwd)
            opts.cwd = parent_dir_path
            M.mode_dir(opts)
        end, exec_silent = true, field_index = false },
        ['default'] = { fn = function()
            if #fzf_lua.get_last_query() == 0 then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_dir(opts)
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
            M.mode_dir(opts)
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
    }
    local cmd_num_files = string.format("find -L %s -maxdepth 1 -mindepth 1 -type d | wc -l", opts.cwd)
    local num_files = tonumber(vim.fn.system(cmd_num_files))
    if num_files and num_files > 0 then
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
    opts = opts or {}
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

    if opts.last_mode == "files" then
        M.mode_files(opts)
    elseif opts.last_mode == "dir" then
        M.mode_dir(opts)
    elseif opts.last_mode == "grep" then
        M.mode_grep(opts)
    else
        print(string.format("fzf-combi-mode: mode %s does not exist", opts.last_mode))
    end
end

M.setup = function(opts)
    M.userset = opts or {}
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
