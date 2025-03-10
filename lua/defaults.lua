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

return {
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
    reset_dir_key = "ctrl-i",
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
