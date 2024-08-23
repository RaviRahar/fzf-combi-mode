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
    _res_data = {},

    res = true,
    change = false,
    default = "browser",

    grep_key = "ctrl-g",
    browser_key = "ctrl-o",
    files_key = "ctrl-k",
    cycle_key = "ctrl-f",
    parent_dir_key = "ctrl-h",
    browser_keys = {
        toggle_hidden_key = "ctrl-z",
        toggle_files_key = "ctrl-y",
        toggle_cycle_key = "ctrl-t",
        goto_path_key = "ctrl-l",
        new_file_key = "ctrl-q",
        new_dir_key = "ctrl-e",
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

M.cmd_get_files_and_dir = function(opts)
    opts.include_files = (opts.include_files ~= nil) and opts.include_files or false
    opts.include_hidden = (opts.include_hidden ~= nil) and opts.include_hidden or false
    local command = nil
    if vim.fn.executable("fd") == 1 then
        if opts.include_files and opts.include_hidden then
            command = string.format("fd --hidden --max-depth 1 --min-depth 1 --no-ignore", opts.fd_opts)
        elseif not opts.include_hidden and opts.include_files then
            command = string.format("fd --max-depth 1 --min-depth 1 --no-ignore", opts.fd_opts)
        elseif opts.include_hidden and not opts.include_files then
            command = string.format("fd --hidden --type d --max-depth 1 --min-depth 1 --no-ignore", opts.fd_opts)
        else
            command = string.format("fd --type d --max-depth 1 --min-depth 1 --no-ignore", opts.fd_opts)
        end
    else
        if opts.find_global_opts == nil then opts.find_global_opts = "" end
        if opts.find_positional_opts == nil then opts.find_positional_opts = "" end

        if opts.include_files and opts.include_hidden then
            command = string.format(
                [[find -L %s -maxdepth 1 -mindepth 1 \( -type d -printf '%s/\n' , ! -type d -printf '%s\n' \)]],
                opts.cwd, "%P", "%P", opts.find_global_opts, opts.find_positional_opts)
        elseif opts.include_files and not opts.include_hidden then
            command = string.format(
                [[find -L %s -maxdepth 1 -mindepth 1 \( ! -regex '.*/\.[^/]*' \) \( -type d -printf '%s/\n' , ! -type d -printf '%s\n' \)]],
                opts.cwd, "%P", "%P", opts.find_global_opts, opts.find_positional_opts)
        elseif not opts.include_files and opts.include_hidden then
            command = string.format([[find -L %s -maxdepth 1 -mindepth 1 -type d -printf '%s/\n']], opts.cwd, "%P",
                opts.find_global_opts, opts.find_positional_opts)
        else
            command = string.format(
                [[find -L %s -maxdepth 1 -mindepth 1 -type d \( ! -regex '.*/\.[^/]*' \) -printf '%s/\n']],
                opts.cwd, "%P", opts.find_global_opts, opts.find_positional_opts)
        end
    end
    return command
end

M.cmd_get_num_files = function(opts)
    opts.include_files = (opts.include_files ~= nil) and opts.include_files or false
    opts.include_hidden = (opts.include_hidden ~= nil) and opts.include_hidden or false
    local cmd_num_files
    if opts.include_files and opts.include_hidden then
        cmd_num_files = string.format([[find -L %s -maxdepth 1 -mindepth 1 | wc -l]], opts.cwd)
    elseif opts.include_files and not opts.include_hidden then
        cmd_num_files = string.format([[find -L %s -maxdepth 1 -mindepth 1 -not -path \'*/.*\' | wc -l]], opts.cwd)
    elseif not opts.include_files and opts.include_hidden then
        cmd_num_files = string.format([[find -L %s -maxdepth 1 -mindepth 1 -type d | wc -l]], opts.cwd)
    else
        cmd_num_files = string.format([[find -L %s -maxdepth 1 -mindepth 1 -type d -not -path \'*/.*\' | wc -l]],
            opts.cwd)
    end
    local num_files = tonumber(vim.fn.system(cmd_num_files))
    if num_files == nil then num_files = 0 end
    return num_files
end

M.set_legend = function(opts, legend)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = string.format("%s", legend)
    return opts
end

M.remove_legend = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = nil
    return opts
end

M.edit_prompt_dir_mode = function(mode)
    -- prefix all mode_dir prompts with Dir:
    local prompt
    if mode == "browser" then
        prompt = "Browser: "
    elseif mode == "files" then
        prompt = "Files: "
    elseif mode == "goto" then
        prompt = "Go To: "
    elseif mode == "creation" then
        prompt = "New: "
    elseif mode == "deletion" then
        prompt = "Delete: "
    elseif mode == "grep" then
        prompt = "Find Word: "
    end
    prompt = prompt .. " > "
    return prompt
end

M.shallow_copy = function(copy, orig)
    local orig_type = type(orig)
    local copy_type = type(copy)
    if orig_type == 'table' then
        if #copy ~= 0 then
            table.clear(copy)
        end
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    -- return copy
end

M.mode_files = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    if opts.res == true then
        if M._is_resuming then
            opts.query = (opts.last_mode == "files") and fzf_lua.get_last_query() or nil
        else
            M._is_resuming = true
        end
        opts.last_mode = "files"
        M.shallow_copy(M._res_data, opts)
    end
    local mode_files_legend = ":: Dir: " .. opts.cwd
    opts = M.set_legend(opts, mode_files_legend)
    opts.fn_transform = nil
    opts.cwd_prompt = false
    opts.prompt = M.edit_prompt_dir_mode("files")
    opts.mode_previous = M.mode_files
    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    M.mode_files(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = fzf_lua.actions.file_edit_or_qf,
        [M.browser_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
        [M.grep_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_grep(opts) end, exec_silent = true, field_index = false },
        [M.browser_keys.new_file_key] = {
            fn = function()
                opts.is_creation_dir = false
                M.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.new_dir_key] = {
            fn = function()
                opts.is_creation_dir = true
                M.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.delete_key] = function(selected)
            M.mode_deletion(opts, selected)
        end,
        [M.browser_keys.goto_path_key] = {
            fn = function()
                M.mode_goto_path(opts)
            end,
            exec_silent = true,
            field_index = false
        },
    }
    fzf_lua.files(opts)
end
M.mode_grep = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    if opts.res == true then
        if M._is_resuming then
            opts.query = (opts.last_mode == "grep") and fzf_lua.get_last_query() or nil
        else
            M._is_resuming = true
        end
        opts.last_mode = "grep"
        M.shallow_copy(M._res_data, opts)
    end
    local mode_grep_legend = ":: Dir: " .. opts.cwd
    opts = M.set_legend(opts, mode_grep_legend)
    opts.fn_transform = nil
    opts.exec_empty_query = true
    opts.mode_previous = M.mode_grep
    opts.prompt = M.edit_prompt_dir_mode("grep")
    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_grep(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    M.mode_grep(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = fzf_lua.actions.file_edit,
        [M.browser_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
        [M.files_key] = { fn = function() M.mode_files(opts) end, exec_silent = true, field_index = false },
        [M.cycle_key] = { fn = function() M.mode_browser(opts) end, exec_silent = true, field_index = false },
    }
    fzf_lua.live_grep_native(opts)
end

M.mode_goto_path = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = M.edit_prompt_dir_mode("goto")
    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                opts.mode_previous(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    opts.is_creation_dir = nil
                    opts.mode_previous(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = {
            fn = function()
                local entity_name = fzf_lua.get_last_query()
                entity_name = fzf_lua.path.tilde_to_HOME(entity_name)
                if entity_name ~= "" then
                    if (vim.fn.isdirectory(entity_name) ~= 0) then
                        opts.cwd = entity_name
                    end
                    if (vim.fn.filereadable(entity_name) ~= 0) then
                        local file_name = fzf_lua.path.basename(entity_name)
                        local file_path = fzf_lua.path.parent(entity_name)
                        opts.cwd = file_path
                        fzf_lua.actions.file_edit({ file_name }, opts)
                    else
                        opts.mode_previous(opts)
                    end
                end
            end,
            field_index = false
        },
    }
    local mode_goto_legend = ":: Dir: " .. opts.cwd
    mode_goto_legend = mode_goto_legend ..
        string.format("\n:: Enter File or Directory Path.")
    opts = M.set_legend(opts, mode_goto_legend)
    fzf_lua.fzf_exec({}, opts)
end


M.mode_creation = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = M.edit_prompt_dir_mode("creation")
    opts.is_creation_dir = (opts.is_creation_dir ~= nil) and opts.is_creation_dir or false
    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                opts.mode_previous(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    opts.is_creation_dir = nil
                    opts.mode_previous(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = {
            fn = function()
                local new_entity_name = fzf_lua.get_last_query()

                if new_entity_name ~= "" then
                    if opts.is_creation_dir then
                        os.execute(string.format("mkdir -p %s", fzf_lua.path.join({ opts.cwd, new_entity_name })))
                    else
                        os.execute(string.format(">> %s", fzf_lua.path.join({ opts.cwd, new_entity_name })))
                    end
                    opts.is_creation_dir = nil
                end

                opts.mode_previous(opts)
            end,
            field_index = true
        },
    }

    local mode_creation_legend = ":: Dir: " .. opts.cwd
    if opts.is_creation_dir then
        mode_creation_legend = mode_creation_legend ..
            string.format("\n:: Enter Directory Name. Then Press Enter. Backspace to go to Browser.")
    else
        mode_creation_legend = mode_creation_legend ..
            string.format("\n:: Enter File Name. Then Press Enter. Backspace to go to Browser.")
    end
    opts = M.set_legend(opts, mode_creation_legend)
    fzf_lua.fzf_exec({}, opts)
end

M.mode_deletion = function(opts, selected)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = M.edit_prompt_dir_mode("deletion")
    local selected_query = selected[1]
    local entity_name = fzf_lua.path.entry_to_file(selected_query).path
    local entiry_path = fzf_lua.path.join({ opts.cwd, entity_name })
    local mode_deletion_legend = ":: Dir: " .. opts.cwd
    mode_deletion_legend = mode_deletion_legend ..
        string.format("\n:: DELETE %s ? Press Enter(Yes)/Backspace(No).", entiry_path)
    opts = M.set_legend(opts, mode_deletion_legend)
    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                opts.mode_previous(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    opts.mode_previous(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = {
            fn = function()
                os.execute(string.format("rm -rf %s &>/dev/null", entiry_path))
                opts.mode_previous(opts)
            end,
            field_index = true
        },
    }
    fzf_lua.fzf_exec({}, opts)
end

M.mode_browser = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    -- opts.fn_transform = function(file_name)
    --     return fzf_lua.make_entry.file(file_name, { file_icons = true, color_icons = true })
    -- end
    if opts.res == true then
        if M._is_resuming then
            opts.query = (opts.last_mode == "browser") and fzf_lua.get_last_query() or nil
        else
            M._is_resuming = true
        end
        opts.last_mode = "browser"
        M.shallow_copy(M._res_data, opts)
    end
    opts.include_hidden = (function() if (opts.include_hidden ~= nil) then return opts.include_hidden else return false end end)()
    opts.include_files = (function() if (opts.include_files ~= nil) then return opts.include_files else return true end end)()
    opts.dir_empty = false
    opts.prompt = M.edit_prompt_dir_mode("browser")
    local browser_mode_legend = ":: Dir: " .. opts.cwd
    browser_mode_legend = browser_mode_legend .. "\n:: Showing Directories"
    if opts.include_files then
        browser_mode_legend = browser_mode_legend .. " :: Showing Files"
    end
    if opts.include_hidden then
        browser_mode_legend = browser_mode_legend .. " :: Showing Hidden"
    end
    opts = M.set_legend(opts, browser_mode_legend)
    opts.mode_previous = M.mode_browser

    opts.actions = {
        [M.parent_dir_key] = {
            fn = function()
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #fzf_lua.get_last_query() == 0 then
                    local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    M.mode_browser(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = function(selected)
            local selected_query = selected[1]
            if opts.dir_empty then
                local parent_dir_path = fzf_lua.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                M.mode_browser(opts)
            else
                local entity_name = fzf_lua.path.entry_to_file(selected_query).path
                local next_path = fzf_lua.path.join({ opts.cwd, entity_name })
                if (vim.fn.isdirectory(next_path) == 0) then
                    fzf_lua.actions.file_edit(selected, opts)
                else
                    opts.cwd = next_path
                    M.mode_browser(opts)
                end
            end
        end,
        [M.files_key] = {
            fn = function()
                opts.prompt = nil
                M.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.grep_key] = {
            fn = function()
                opts.prompt = nil
                M.mode_grep(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.cycle_key] = {
            fn = function()
                opts.prompt = nil
                M.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.toggle_hidden_key] = {
            fn = function()
                opts.include_hidden = not opts.include_hidden
                M.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.toggle_files_key] = {
            fn = function()
                opts.include_files = not opts.include_files
                M.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.toggle_cycle_key] = {
            fn = function()
                if opts.include_hidden and opts.include_files then
                    opts.include_hidden = false
                    opts.include_files = false
                    M.mode_browser(opts)
                elseif opts.include_hidden or opts.include_files then
                    opts.include_hidden = true
                    opts.include_files = true
                    M.mode_browser(opts)
                else
                    opts.include_hidden = false
                    opts.include_files = true
                    M.mode_browser(opts)
                end
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.new_file_key] = {
            fn = function()
                opts.is_creation_dir = false
                M.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.new_dir_key] = {
            fn = function()
                opts.is_creation_dir = true
                M.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [M.browser_keys.delete_key] = function(selected)
            M.mode_deletion(opts, selected)
        end,
        [M.browser_keys.goto_path_key] = {
            fn = function()
                M.mode_goto_path(opts)
            end,
            exec_silent = true,
            field_index = false
        },
    }
    if M.cmd_get_num_files(opts) > 0 then
        fzf_lua.fzf_exec(M.cmd_get_files_and_dir(opts), opts)
    else
        opts.dir_empty = true
        fzf_lua.fzf_exec({ "Empty Directory. Go Back?" }, opts)
    end
end

M.mode_combi = function(opts)
    if not M._setup_done then
        M.setup()
    end

    opts = type(opts) == "table" and opts or {}

    -- for backspace functionality on empty query
    opts.keymap = { fzf = { ["backward-eof"] = "print(_back_eof)+accept" } }

    if opts.res == nil then
        opts.res = M.res
    end

    if opts.change == nil then
        opts.change = M.change
    end

    if opts.mode == nil then
        opts.mode = M.default
    end
    opts.last_mode = opts.mode

    if not opts.res or not M._is_resuming then
        M.userset_override = opts
    else
        M.userset_override = M._res_data
        if opts.change then
            M.userset_override.last_mode = opts.mode
        end
    end

    -- override options by directly accessing through fzf config
    -- setmetatable(M.userset_override, { __index = fzf_lua.config.globals })
    local mode = M.userset_override.last_mode
    if mode == "files" then
        M.mode_files(M.userset_override)
    elseif mode == "browser" then
        M.mode_browser(M.userset_override)
    elseif mode == "grep" then
        M.mode_grep(M.userset_override)
    else
        print(string.format("fzf-combi-mode: mode %s does not exist", mode))
    end
end

M.setup = function(opts)
    M.userset = type(opts) == "table" and opts or {}
    -- first check in userset if setting found
    -- __newmethod allows values in defaults values to be changed directly
    -- For ex: instead of M.defaults.res=false we can use M.res=false
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

    M.mode_combi(opts)
end

return M
