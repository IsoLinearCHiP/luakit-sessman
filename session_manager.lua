-----------------------------------------------------------
-- implement an interactive session management           --
-- © 2011-2012 0mark@unserver.de, isolin-chip@gmail.com  --
-----------------------------------------------------------

local os = require "os"
local webview = webview
local table = table
local string = string
local lousy = require "lousy"
local capi = { luakit = luakit, sqlite3 = sqlite3 } -- FIXME: not used, necisarry?
local window = window

module "session_manager"

-- Setup signals on session_manager module
lousy.signal.setup(_M, true)

webview.init_funcs.sess_man = function (view, w)
    -- Add items
    view:add_signal("load-status", function (v, status)
        -- Don't add history items when in private browsing mode
        if v:get_property("enable-private-browsing") then return end

        -- We use the "committed" status here because we are not interested in
        -- any intermediate uri redirects taken before reaching the real uri.
        if status == "committed" then
            w:save_all_sessions()
        end
    end)
end

window.methods.save_all_sessions = function (w)
    local wins = {}
    for _, w in pairs(window.bywidget) do table.insert(wins, w) end
    session.save(wins)
end

-- vim: et:sw=4:ts=8:sts=4:tw=80
