local BrowserMode = {}
BrowserMode.__index = BrowserMode

BrowserMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, BrowserMode)
    return self
end

BrowserMode.run = function(self, opts)
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    -- opts.fn_transform = function(file_name)
    --     return fzf_lua.make_entry.file(file_name, { file_icons = true, color_icons = true })
    -- end
    if opts.res == true then
        if CombiMode._is_resuming then
            opts.query = (opts.last_mode == "browser") and CombiMode.search_program.get_last_query() or nil
        else
            CombiMode._is_resuming = true
        end
        opts.last_mode = "browser"
        CombiMode.shallow_copy_tables(CombiMode._res_data, opts)
    end
    opts.include_hidden = (function() if (opts.include_hidden ~= nil) then return opts.include_hidden else return false end end)()
    opts.include_files = (function() if (opts.include_files ~= nil) then return opts.include_files else return true end end)()
    opts.dir_empty = false
    opts.prompt = CombiMode.edit_prompt_dir_mode("browser")
    local browser_mode_legend = ":: Dir: " .. opts.cwd
    browser_mode_legend = browser_mode_legend .. "\n:: Showing Directories"
    if opts.include_files then
        browser_mode_legend = browser_mode_legend .. " :: Showing Files"
    end
    if opts.include_hidden then
        browser_mode_legend = browser_mode_legend .. " :: Showing Hidden"
    end
    opts = CombiMode.set_legend(opts, browser_mode_legend)
    opts.mode_previous = BrowserMode.new(CombiMode)

    opts.actions = {
        [CombiMode.parent_dir_key] = {
            fn = function()
                local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                CombiMode.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.reset_dir_key] = {
            fn = function()
                opts.cwd = vim.loop.cwd()
                CombiMode.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #CombiMode.search_program.get_last_query() == 0 then
                    local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    CombiMode.mode_browser(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = function(selected)
            local selected_query = selected[1]
            if opts.dir_empty then
                local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                CombiMode.mode_browser(opts)
            else
                local entity_name = CombiMode.search_program.path.entry_to_file(selected_query).path
                local next_path = CombiMode.search_program.path.join({ opts.cwd, entity_name })
                if (vim.fn.isdirectory(next_path) == 0) then
                    CombiMode.search_program.actions.file_edit(selected, opts)
                else
                    opts.cwd = next_path
                    CombiMode.mode_browser(opts)
                end
            end
        end,
        [CombiMode.files_key] = {
            fn = function()
                opts.prompt = nil
                CombiMode.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.grep_key] = {
            fn = function()
                opts.prompt = nil
                CombiMode.mode_grep(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.cycle_key] = {
            fn = function()
                opts.prompt = nil
                CombiMode.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.toggle_hidden_key] = {
            fn = function()
                opts.include_hidden = not opts.include_hidden
                CombiMode.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.toggle_files_key] = {
            fn = function()
                opts.include_files = not opts.include_files
                CombiMode.mode_browser(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.toggle_cycle_key] = {
            fn = function()
                if opts.include_hidden and opts.include_files then
                    opts.include_hidden = false
                    opts.include_files = false
                    CombiMode.mode_browser(opts)
                elseif opts.include_hidden or opts.include_files then
                    opts.include_hidden = true
                    opts.include_files = true
                    CombiMode.mode_browser(opts)
                else
                    opts.include_hidden = false
                    opts.include_files = true
                    CombiMode.mode_browser(opts)
                end
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.new_file_key] = {
            fn = function()
                opts.is_creation_dir = false
                CombiMode.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.new_dir_key] = {
            fn = function()
                opts.is_creation_dir = true
                CombiMode.mode_creation(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.browser_keys.delete_key] = function(selected)
            CombiMode.mode_deletion(opts, selected)
        end,
        [CombiMode.browser_keys.goto_path_key] = {
            fn = function()
                CombiMode.mode_goto_path(opts)
            end,
            exec_silent = true,
            field_index = false
        },
    }
    if CombiMode.cmd_get_num_files(opts) > 0 then
        CombiMode.search_program.fzf_exec(CombiMode.cmd_get_files_and_dir(opts), opts)
    else
        opts.dir_empty = true
        CombiMode.search_program.fzf_exec({ "Empty Directory. Go Back?" }, opts)
    end
end

return setmetatable(BrowserMode, { __call = BrowserMode.new })
