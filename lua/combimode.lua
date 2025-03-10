--
--
local status, fzf_lua = pcall(require, 'fzf-lua')
if not status then
    print(fzf_lua)
    return
end
--
--
local CombiMode = {}

CombiMode.search_program = fzf_lua

local BrowserMode = require('modes.browsermode')
local FilesMode = require('modes.filesmode')
local GrepMode = require('modes.grepmode')
local CreationMode = require('modes.creationmode')
local DeletionMode = require('modes.deletionmode')
local GotoPathMode = require('modes.gotopathmode')

-- dependency injection
CombiMode.mode_browser = BrowserMode(CombiMode)
CombiMode.mode_files = FilesMode(CombiMode)
CombiMode.mode_grep = GrepMode(CombiMode)
CombiMode.mode_creation = CreationMode(CombiMode)
CombiMode.mode_deletion = DeletionMode(CombiMode)
CombiMode.mode_goto_path = GotoPathMode(CombiMode)

CombiMode.common_utils = require('commonutils')

-- defaults are stored here
CombiMode.defaults = require('defaults')
-- values of CombiMode.setup() in config will be stored here
CombiMode.userset = {}

CombiMode.setup = function(opts)
    CombiMode.userset = type(opts) == "table" and opts or {}
    -- first check in userset if setting found
    -- __newmethod allows values in defaults values to be changed directly
    -- For ex: instead of CombiMode.defaults.res=false we can use CombiMode.res=false
    local mt = { __index = CombiMode.userset, __newindex = CombiMode.defaults }
    -- So that values in common_utils are directly accessbile with CombiMode
    CombiMode.common_utils.merge_tables(mt.__index, CombiMode.common_utils)
    setmetatable(CombiMode, mt)
    -- if not then check in defaults
    setmetatable(CombiMode.userset, { __index = CombiMode.defaults })
    CombiMode._setup_done = true
end

-- Discard first argument (it is self)
CombiMode.run = function(opts)
    if not CombiMode._setup_done then
        CombiMode.setup()
    end

    opts = type(opts) == "table" and opts or {}

    -- for backspace functionality on empty query
    opts.keymap = { fzf = { ["backward-eof"] = "print(_back_eof)+accept" } }

    if opts.res == nil then
        opts.res = CombiMode.res
    end

    if opts.change == nil then
        opts.change = CombiMode.change
    end

    if opts.mode == nil then
        opts.mode = CombiMode.default
    end
    opts.last_mode = opts.mode

    -- used to override useropts by directly accessing through combi-mode
    local userset_override = {}

    if not opts.res or not CombiMode._is_resuming then
        userset_override = opts
    else
        userset_override = CombiMode._res_data
        if opts.change then
            userset_override.last_mode = opts.mode
        end
    end

    -- override options by directly accessing through fzf config
    -- setmetatable(CombiMode.userset_override, { __index = fzf_lua.config.globals })
    local mode = userset_override.last_mode
    if mode == "files" then
        CombiMode.mode_files(userset_override)
    elseif mode == "browser" then
        CombiMode.mode_browser(userset_override)
    elseif mode == "grep" then
        CombiMode.mode_grep(userset_override)
    else
        print(string.format("fzf-combi-mode: mode %s does not exist", mode))
    end
end

return CombiMode
