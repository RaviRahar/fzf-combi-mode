local GrepMode = {}
GrepMode.__index = GrepMode

GrepMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, GrepMode)
    return self
end

GrepMode.run = function(self, opts)
    -- used after dependency injection
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    if opts.res == true then
        if CombiMode._is_resuming then
            opts.query = (opts.last_mode == "grep") and CombiMode.search_program.get_last_query() or nil
        else
            CombiMode._is_resuming = true
        end
        opts.last_mode = "grep"
        CombiMode.shallow_copy_tables(CombiMode._res_data, opts)
    end
    local mode_grep_legend = ":: Dir: " .. opts.cwd
    opts = CombiMode.set_legend(opts, mode_grep_legend)
    opts.fn_transform = nil
    opts.exec_empty_query = true
    opts.mode_previous = GrepMode.new(CombiMode)

    opts.prompt = CombiMode.edit_prompt_dir_mode("grep")
    opts.actions = {
        [CombiMode.parent_dir_key] = {
            fn = function()
                local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                CombiMode.mode_grep(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.reset_dir_key] = {
            fn = function()
                opts.cwd = vim.loop.cwd()
                CombiMode.mode_grep(opts)
            end,
            exec_silent = true,
            field_index = false
        },

        ['_back_eof'] = {
            fn = function()
                if #CombiMode.search_program.get_last_query() == 0 then
                    local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    CombiMode.mode_grep(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = CombiMode.search_program.actions.file_edit,
        [CombiMode.browser_key] = { fn = function() CombiMode.mode_browser(opts) end, exec_silent = true, field_index = false },
        [CombiMode.files_key] = { fn = function() CombiMode.mode_files(opts) end, exec_silent = true, field_index = false },
        [CombiMode.cycle_key] = { fn = function() CombiMode.mode_browser(opts) end, exec_silent = true, field_index = false },
    }
    CombiMode.search_program.live_grep_native(opts)
end

return setmetatable(GrepMode, { __call = GrepMode.new })
