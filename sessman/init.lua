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
local window = window
local tostring = tostring
local debug = debug

-- Grab the luakit environment we need
local lousy = require("lousy")
local chrome = require("chrome")
-- local markdown = require("markdown")
-- local sql_escape = lousy.util.sql_escape
local add_binds = add_binds
local add_cmds = add_cmds
local webview = webview
local capi = {
    luakit = luakit
}

-- Advanced sessionmanager inspired by SessionManager Extension to Firefox
module("sessionman")

--------------------
-- utility functions
--------------------

function getcwd()
    local path = debug.getinfo(1).short_src
    local dir,_ = string.gsub(path, "^(.+/)[^/]+$", "%1")
    return dir
end

---------------------------------------------
-- OOP interface to windows tabs and sessions
---------------------------------------------

Tab = {
    __index = { uri = "", title = "", hist = {} },
    -- FIXME: should init hist in new()

    __tostring = function(self)
        -- print("Tab tostring")
        return "Tab { title: " .. self.title .. " , uri: " .. self.uri .. " }"
    end,

    new = function(self, o)
        local o = o or {}
        setmetatable(o, Tab)
        -- print("creating new Tab")
        return o
    end
}

Tabs = {
    __index = function(t, k)
        t[k] = Tab:new()
        return t[k]
    end,

    __tostring = function(self)
        -- print("Tabs tostring")
        local tmp = {}
        for i,s in ipairs(self) do
            -- print(i, s)
            table.insert(tmp,tostring(s))
        end
        return "[ " .. table.concat(tmp,",") .. " ]"
    end,

    new = function(self, o)
        local o = o or {}
        setmetatable(o, Tabs)
        -- print("creating new Tabs")
        return o
    end
}

Window = {
    __index = { currtab = 0, tab = {} },
    -- FIXME: should init tab in new()

    __tostring = function(self)
        -- print("Window tostring")
        return "Window { currtab: " .. self.currtab .. " , tabs: " .. tostring(self.tab) .. " }"
    end,

    new = function(self, o)
        local o = o or {}
        setmetatable(o, Window)
        -- print("creating new Window")
        return o
    end
}

Windows = {
    __index = function(t, k)
        t[k] = Window:new()
        return t[k]
    end,

    __tostring = function(self)
        -- print("Windows tostring")
        local tmp = {}
        for i,s in ipairs(self) do
            -- print(i, s)
            table.insert(tmp,tostring(s))
        end
        return "[ " .. table.concat(tmp,",") .. " ]"
    end,

    new = function(self, o)
        local o = o or {}
        setmetatable(o, Windows)
        -- print("creating new Windows")
        return o
    end,
}

Session = {
    __index = { name = "", ctime = nil, mtime = nil, win = {}, sync = false },
    -- FIXME: should init win in new()

    __tostring = function(self)
        -- print("Session tostring")
        return "Session { " ..
               "name: " .. self.name ..
               " , sync: " .. tostring(self.sync) ..
               " , ctime: " .. tostring(self.ctime) ..
               " , mtime: " .. tostring(self.mtime) ..
               " , win: " .. tostring(self.win) ..
               " }"
    end,

    new = function(self, o)
        local o = o or {}
        setmetatable(o, Session)
        -- print("creating new Session")
        return o
    end
}


-------------------------
-- JS interface functions
-------------------------

function get()
    -- get all active windows
    local wins = {}
    for _,w in pairs(window.bywidget) do table.insert(wins, w) end

    -- setup basic info for session
    local session = Session:new()
    session.name = "Current"
    session.ctime = "now"
    session.mtime = "now"
    session.win = Windows:new()
    session.sync = false

    -- iterate over windows and add tabs to session
    for wi, w in ipairs(wins) do
        local current = w.tabs:current()
        -- print(current, wi)
        -- table.foreach(session.win[wi], print)
        session.win[wi] = Window:new()
        session.win[wi].currtab = current
        session.win[wi].tab = Tabs:new()
        for ti, tab in ipairs(w.tabs.children) do
            -- print("adding a new tab: " .. ti)
            session.win[wi].tab[ti] = Tab:new({uri= tab.uri, title=tab.title, hist=tab.history})
            -- session.win[wi].tab[ti].uri=tab.uri
            -- session.win[wi].tab[ti].title=tab.title
        end
        print(session)
    end

    -- session = {
    --  [1] = {
    --      name = "test 1",
    --      ctime = nil,
    --      mtime = nil,
    --         sync = false,
    --         windows = {
    --          title = "title 1",
    --          uri = "http://1"
    --         }
    --     }
    -- }
    return { [1] = session }
end

export_funcs = {
    sessionman_add    = add,
    sessionman_get    = _M.get,
    sessionman_remove = remove,
}

-----------------------------
-- add chrome interface items
-----------------------------

stylesheet = [===[
// this space intentionally left blank
]===]

local html = lousy.load(getcwd() .. "sessman.html")

local main_js = lousy.load(getcwd() .. "sessman.js")

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
