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

-- local json = require("sessman.json")
-- FIXME: should work?, but doesnt
require("sessman.json")
local json = json
-- does work

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

function basedir() 
    return os.getenv("XDG_DATA_HOME") or os.getenv("HOME") .. "/.local/share"
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
    end,

    clone = function(self)
        local res = Tab:new()

        res.uri   = self.uri
        res.title = self.title
        res.hist  = self.hist -- FIXME should prob clone this too
    end,
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
    end,

    clone = function(self)
        local res = Tabs:new()

        for ti,t in ipairs(self) do
            res[ti] = t:clone()
        end
    end,
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
    end,

    clone = function(self)
        local res = Window:new()

        res.currtab = self.currtab
        res.tab     = self.tab
    end,
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

    clone = function(self)
        local res = Windows:new()

        for wi,w in ipairs(self) do
            res[wi] = w:clone()
        end
    end,
}

Session = {
    -- __index = { name = "", ctime = nil, mtime = nil, win = {}, sync = false, },
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
        local def = { name = "", ctime = nil, mtime = nil, win = {}, sync = false, }
        -- local o = o or {}
        -- print("creating new Session")
        return setmetatable(o or def, Session)
    end,

    dump = function(self)
        local data = { name = self.name, ctime = self.ctime, mtime = self.mtime, win = self.win, sync = false }
        return json.encode(data)
    end,

    parse = function(self, str)
        local data = json.decode(str)
        if data then
            self.name  = data.name
            self.ctime = data.ctime
            self.mtime = data.mtime
            self.win   = data.win
        end
        return self.win
    end,

    copy_curr = function(self)
        -- get all active windows
        local wins = {}
        for _,w in pairs(window.bywidget) do table.insert(wins, w) end

        -- setup basic info for session
        self.name  = "Current"
        self.ctime = "now"
        self.mtime = "now"
        self.win   = Windows:new()
        self.sync  = false

        -- iterate over windows and add tabs to self
        for wi, w in ipairs(wins) do
            local current = w.tabs:current()
            -- print(current, wi)
            -- table.foreach(self.win[wi], print)
            self.win[wi] = Window:new()
            self.win[wi].currtab = current
            self.win[wi].tab = Tabs:new()
            for ti, tab in ipairs(w.tabs.children) do
                -- print("adding a new tab: " .. ti)
                self.win[wi].tab[ti] = Tab:new({uri= tab.uri, title=tab.title, hist=tab.history})
                -- self.win[wi].tab[ti].uri=tab.uri
                -- self.win[wi].tab[ti].title=tab.title
            end
        end
    end,

    clone = function(self)
        local res = Session:new()

        res.name  = self.name
        res.ctime = self.ctime
        res.mtime = self.mtime
        res.win   = self.win:clone()
    end,
}
Session.__index = Session -- dies ist die "mach mal das OOP heile Zeile"


----------------------------------------
-- session loading and storing functions
-- from sess_saver.lua (see attrib)
----------------------------------------

-- Utility functions.
local function rm(file)
    luakit.spawn(string.format("rm %q", file))
end

local function file(path,fname)
    return path .. "/" .. fname
end

-- Session functions.
session = {
    -- functions provided by (old) built-in session handler
    save = function (wins)
    end,

    load = function (delete)
    end,

    restore = function (delete)
    end,

    -- The directory where sessions are stored
    -- FIXME: Maybe the storage dir should be considdered a config rather than data
    path = basedir() .. "/luakit/sessions/",

    -- Save all tabs of current window to session file (if it exists).
    store = function (w, session_data, force)
        -- abort if no session_data or empty name
        if not session_data or not session_data.name then return false end

        local name = session_data.name
        if name then
            -- do the saving
            if #session_data.win > 0 then
                res = session.write(name,session_data,force)
                if res == "old" then
                    w:notify("\"" .. name .. "\" written")
                elseif res == "new" then
                    w:notify("\"" .. name .. "\" [New] written")
                else
                    w:error("\"" .. name .. "\" exists in session directory (add ! to override)")
                    return false
                end
            end
        else
            w:error("No session name")
            return false
        end
        return true
    end,

    -- Read urls from session file.
    read = function (name)
        local path = session.path
        local sfile = file(path,name)
        if not os.exists(sfile) then return end
        local fh = io.open(sfile, "r")
        local sess = Session:new()
        sess:parse(fh:read("*all"))
        io.close(fh)
        return sess
    end,

    -- Write tab data.
    write = function (name, sess, force)
        local sfile = file(session.path,name) -- will save to path/name
        local age = os.exists(sfile) and "old" or "new"
        if age == "old" and not force then return false end
        local fh = io.open(sfile, "w")
        fh:write(sess:dump())
        io.close(fh)
        return age
    end,

    -- Set the name of the session for the window.
    setname = function (w, name, force)
        if os.exists(file(session.path,name)) and not force then return false end
        w.session = name
        w.view:emit_signal("property::session-name")
        return true
    end,

    -- Load new session from file; optionally replace existing session.
    sload = function (w, name, replace)
        if name then
            local sess_data = session.read(name)
            if sess_data then
                if replace then
                    -- backup current session first
                    local curr_sess = Session:new()
                    curr_sess:copy_curr()

                    -- clear tabs from current window
                    local numwin = #window.bywidget
                    for _,w in pairs(window.bywidget) do 
                        if numwin > 1 then
                            w:close()
                            numwin = numwin - 1
                        else
                            while w.tabs:count() ~= 0 do
                                w:close_tab(nil, false)
                            end
                        end
                    end
                end
                session.open(w,sess_data)
                if replace then
                    session.setname(w,name,true)
                end
                if replace then
                    w:notify("\"" .. name .. "\" loaded")
                else
                    w:notify("\"" .. name .. "\" merged")
                end
            else
                w:error("\"" .. name .. "\" does not exist")
            end
        else
            w:error("No session name")
        end
    end,

    -- Open new tabs from table of tab data.
    open = function (w,sess_data)
        local w = w
        if sess_data and w then -- load new tabs
            for _, win in ipairs(sess_data.win) do
                for _, tab in ipairs(win.tab) do
                    w:new_tab(tab.url, tab.hist)
                end
                w = window.new()
            end
        end
    end,
}

-------------------------
-- JS interface functions
-------------------------

function get()
    -- setup basic info for session
    local sess = Session:new()
    -- print(sess.getmetatable())
    -- Session.copy_curr(sess)
    print(sess)
    -- sess:copy_curr()
    sess:copy_curr()

    -- sess = {
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
    return { [1] = sess }
end

function add()
    -- FIXME: crude hack to until i know how to get curr window
    w = {
        notify = function(str)
            print('WARN: ' .. tostring(str))
        end,

        error = function(str)
            print('ERR : ' .. tostring(str))
        end,
    }
    -- setup basic info for session
    local sess = Session:new()
    -- print(sess.getmetatable())
    -- Session.copy_curr(sess)
    -- sess:copy_curr()
    sess:copy_curr()
    sess.name = "test"
    print(sess)

    return session.store(w, sess,false)
end

export_funcs = {
    sessionman_add    = _M.add,
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
