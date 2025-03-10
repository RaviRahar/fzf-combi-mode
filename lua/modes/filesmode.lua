local FilesMode = {}
FilesMode.__index = FilesMode

FilesMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, FilesMode)
    return self
end

FilesMode.run = function(self, opts)
    -- used after dependency injection
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    if opts.res == true then
        if CombiMode._is_resuming then
            opts.query = (opts.last_mode == "files") and CombiMode.search_program.get_last_query() or nil
        else
            CombiMode._is_resuming = true
        end
        opts.last_mode = "files"
        CombiMode.shallow_copy_tables(CombiMode._res_data, opts)
    end
    local mode_files_legend = ":: Dir: " .. opts.cwd
    opts = CombiMode.set_legend(opts, mode_files_legend)
    opts.fn_transform = nil
    opts.cwd_prompt = false
    opts.prompt = CombiMode.edit_prompt_dir_mode("files")
    opts.mode_previous = FilesMode.new(CombiMode)

    opts.actions = {
        [CombiMode.parent_dir_key] = {
            fn = function()
                local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
                CombiMode.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.reset_dir_key] = {
            fn = function()
                opts.cwd = vim.loop.cwd()
                CombiMode.mode_files(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #CombiMode.search_program.get_last_query() == 0 then
                    local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                    opts.cwd = parent_dir_path
                    CombiMode.mode_files(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = CombiMode.search_program.actions.file_edit_or_qf,
        [CombiMode.browser_key] = { fn = function() CombiMode.mode_browser(opts) end, exec_silent = true, field_index = false },
        [CombiMode.grep_key] = { fn = function() CombiMode.mode_grep(opts) end, exec_silent = true, field_index = false },
        [CombiMode.cycle_key] = { fn = function() CombiMode.mode_grep(opts) end, exec_silent = true, field_index = false },
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
    CombiMode.search_program.files(opts)
end

return setmetatable(FilesMode, { __call = FilesMode.new })
