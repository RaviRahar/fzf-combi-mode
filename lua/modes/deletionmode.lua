local DeletionMode = {}
DeletionMode.__index = DeletionMode

DeletionMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, DeletionMode)
    return self
end

DeletionMode.run = function(self, opts)
    -- used after dependency injection
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = CombiMode.edit_prompt_dir_mode("deletion")
    local selected_query = selected[1]
    local entity_name = CombiMode.search_program.path.entry_to_file(selected_query).path
    local entiry_path = CombiMode.search_program.path.join({ opts.cwd, entity_name })
    local mode_deletion_legend = ":: Dir: " .. opts.cwd
    mode_deletion_legend = mode_deletion_legend ..
        string.format("\n:: DELETE %s ? Press Enter(Yes)/Backspace(No).", entiry_path)
    opts = CombiMode.set_legend(opts, mode_deletion_legend)
    opts.actions = {
        [CombiMode.parent_dir_key] = {
            fn = function()
                opts.mode_previous(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        [CombiMode.reset_dir_key] = {
            fn = function()
                opts.cwd = vim.loop.cwd()
                opts.mode_previous(opts)
            end,
            exec_silent = true,
            field_index = false
        },
        ['_back_eof'] = {
            fn = function()
                if #CombiMode.search_program.get_last_query() == 0 then
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
    CombiMode.search_program.fzf_exec({}, opts)
end

return setmetatable(DeletionMode, { __call = DeletionMode.new })
