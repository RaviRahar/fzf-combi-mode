local CreationMode = {}
CreationMode.__index = CreationMode

CreationMode.new = function(class, CombiMode)
    -- for dependency injection
    class.combimode = CombiMode
    class.__call = class.run

    local self = setmetatable({}, CreationMode)
    return self
end

CreationMode.run = function(self, opts)
    -- used after dependency injection
    local CombiMode = self.combimode

    opts = type(opts) == "table" and opts or {}
    opts.cwd = opts.cwd or vim.loop.cwd()
    if opts.__call_opts then opts.__call_opts = nil end
    opts.prompt = CombiMode.edit_prompt_dir_mode("creation")
    opts.is_creation_dir = (opts.is_creation_dir ~= nil) and opts.is_creation_dir or false
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
                local new_entity_name = CombiMode.search_program.get_last_query()

                if new_entity_name ~= "" then
                    if opts.is_creation_dir then
                        os.execute(string.format("mkdir -p %s", CombiMode.search_program.path.join({ opts.cwd, new_entity_name })))
                    else
                        os.execute(string.format(">> %s", CombiMode.search_program.path.join({ opts.cwd, new_entity_name })))
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
    opts = CombiMode.set_legend(opts, mode_creation_legend)
    CombiMode.search_program.fzf_exec({}, opts)
end

return setmetatable(CreationMode, { __call = CreationMode.new })
