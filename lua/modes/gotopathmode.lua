local GotoPathMode = {}
GotoPathMode.__index = GotoPathMode

GotoPathMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, GotoPathMode)
    return self
end

GotoPathMode.run = function(self, opts)
    -- used after dependency injection
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = CombiMode.edit_prompt_dir_mode("goto")
    opts.actions = {
        [CombiMode.parent_dir_key] = {
            fn = function()
                local parent_dir_path = CombiMode.search_program.path.parent(opts.cwd)
                opts.cwd = parent_dir_path
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
                    opts.is_creation_dir = nil
                    opts.mode_previous(opts)
                end
            end,
            field_index = false
        },
        ['enter'] = {
            fn = function()
                local entity_name = CombiMode.search_program.get_last_query()
                entity_name = CombiMode.search_program.path.tilde_to_HOME(entity_name)
                if entity_name ~= "" then
                    if (vim.fn.isdirectory(entity_name) ~= 0) then
                        opts.cwd = entity_name
                    end
                    if (vim.fn.filereadable(entity_name) ~= 0) then
                        local file_name = CombiMode.search_program.path.basename(entity_name)
                        local file_path = CombiMode.search_program.path.parent(entity_name)
                        opts.cwd = file_path
                        CombiMode.search_program.actions.file_edit({ file_name }, opts)
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
    opts = CombiMode.set_legend(opts, mode_goto_legend)
    CombiMode.search_program.fzf_exec({}, opts)
end

return setmetatable(GotoPathMode, { __call = GotoPathMode.new })
