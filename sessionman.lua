---------------------------------------------------------------------------
-- @author IsoLinearCHiP &lt;isolin.chip@gmail.com&gt;
---------------------------------------------------------------------------

-- Grab environment we need
local util = require("lousy.util")

-- Grab what we need from the Lua environment
local table = table
local string = string
local io = io
local print = print
local pairs = pairs
local ipairs = ipairs
local math = math
local assert = assert
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local type = type
local os = os
local error = error

-- Grab the luakit environment we need
local bookmarks = require("bookmarks")
local lousy = require("lousy")
local chrome = require("chrome")
-- local markdown = require("markdown")
local sql_escape = lousy.util.sql_escape
local add_binds = add_binds
local add_cmds = add_cmds
local webview = webview
local capi = {
    luakit = luakit
}

-- Advanced sessionmanager inspired by SessionManager Extension to Firefox
module("sessionman")

-- Display the bookmark uri and title.
show_uri = false

stylesheet = [===[
// this space intentionally left blank
]===]


local html = [==[
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Sessionmanager</title>
    <style type="text/css">
        {%stylesheet}
    </style>
    <!-- <script type="text/javascript" src="http://code.jquery.com/jquery-1.8.1.js"></script> -->
</head>
<body>
    <div id="session-list">innerHTML</div>
    <div id="window-list" style="position: absolute;"></div>
    <div id="controls" stlye="position: absolute;">
        <input type="button" id="add-button" value="Add" />
        <input type="button" id="submit-button" value="Save" />
        <input type="button" id="cancel-button" value="Cancel" />
    </div>
</body>
]==]

local main_js = [=[
$(document).ready(function () { 'use strict'

    var session_list = $("#session-list"), window_list = $("#window-list");

    var sessions = sessionman_get();
    alert(sessions);
    alert(session_list.id);
    session_list.innerHTML = "test";
    $("#add-button").click(function() {alert('Add clicked'); session_list.innerHTML = "test2";});
    alert(session_list.innerHTML)
})
]=]

function get() 
    return "Hello World!"
end

export_funcs = {
    sessionman_add    = add,
    sessionman_get    = _M.get,
    sessionman_remove = remove,
}

chrome.add("sessionman", function (view, meta)
    local uri = "luakit://sessionman/"

    -- local style = chrome.stylesheet .. _M.stylesheet
    local style = ""

    if not _M.show_uri then
        style = style .. " .bookmark .uri { display: none !important; } "
    end

    local html = string.gsub(html, "{%%(%w+)}", { stylesheet = style })

    view:load_string(html, uri)

    function on_first_visual(_, status)
        -- Wait for new page to be created
        if status ~= "first-visual" then return end

        -- Hack to run-once
        view:remove_signal("load-status", on_first_visual)

        -- Double check that we are where we should be
        if view.uri ~= uri then return end

        -- Export luakit JS<->Lua API functions
        for name, func in pairs(export_funcs) do
            view:register_function(name, func)
        end

        view:register_function("reset_mode", function ()
            meta.w:set_mode() -- HACK to unfocus search box
        end)

        -- Load jQuery JavaScript library
        local jquery = lousy.load("lib/jquery.min.js")
        local _, err = view:eval_js(jquery, { no_return = true })
        assert(not err, err)

        -- Load main luakit://sessionman/ JavaScript
        local _, err = view:eval_js(main_js, { no_return = true })
        assert(not err, err)
    end

    view:add_signal("load-status", on_first_visual)
end)

chrome_page = "luakit://sessionman/"

-- local key, buf = lousy.bind.key, lousy.bind.buf
-- add_binds("normal", {
--     buf("^gs$", "Open session manager in the current tab.",
--         function(w)
--             w:navigate(chrome_page)
--         end),
-- 
--     buf("^gS$", "Open session manager in a new tab.",
--         function(w)
--             w:new_tab(chrome_page)
--         end)
-- })
-- 
local cmd = lousy.bind.cmd
add_cmds({
    cmd("sessionman", function (w)
            w:new_tab(chrome_page)
        end),
})
