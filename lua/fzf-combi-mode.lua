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

-- used to check if plugin is resuming
M._resuming = false
M._setup_done = false
M._resume_data = {}

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
        M._resuming = true
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
        M._resuming = true
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
        M._resuming = true
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

    if opts.resume and M._resuming then
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
    opts = opts or {}

    M.resume = opts.resume or true
    M.default = opts.default or "files"

    local keys = opts.keys or {}
    M.grep_key = keys.grep_key or "ctrl-g"
    M.dir_key = keys.dir_key or "ctrl-i"
    M.files_key = keys.files_key or "ctrl-b"
    M.cycle_key = keys.cycle_key or "ctrl-f"
    M.parent_dir_key = keys.parent_dir_key or "ctrl-h"

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
