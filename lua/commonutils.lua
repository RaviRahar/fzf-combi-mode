local CommonUtils = {}

CommonUtils.cmd_get_files_and_dir = function(opts)
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

CommonUtils.cmd_get_num_files = function(opts)
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

CommonUtils.set_legend = function(opts, legend)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = string.format("%s", legend)
    return opts
end

CommonUtils.remove_legend = function(opts)
    opts = type(opts) == "table" and opts or {}
    opts.fzf_opts = type(opts.fzf_opts) == "table" and opts.fzf_opts or {}
    opts.fzf_opts["--header"] = nil
    return opts
end

CommonUtils.edit_prompt_dir_mode = function(mode)
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

CommonUtils.shallow_copy_tables = function(copy, orig)
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
    return copy
end

CommonUtils.merge_tables = function(mergeto, orig)
    local orig_type = type(orig)
    local mergeto_type = type(mergeto)
    if orig_type == 'table' and mergeto_type == 'table' then
        for orig_key, orig_value in pairs(orig) do
            mergeto[orig_key] = orig_value
        end
    end
end

return CommonUtils
