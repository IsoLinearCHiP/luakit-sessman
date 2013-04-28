---------------------------------------------------------------------------
-- @author IsoLinearCHiP <isolin.chip@gmail.com>
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
local assert = assert
local setmetatable = setmetatable
local os = os
local error = error
local window = window
local tostring = tostring
local debug = debug
local lfs = lfs

-- Grab the luakit environment we need
local lousy = require("lousy")
local chrome = require("chrome")
-- local markdown = require("markdown")
-- local sql_escape = lousy.util.sql_escape
local add_binds = add_binds
local add_cmds = add_cmds
local capi = {
    luakit = luakit
}

require("sessman.SessData")
local Session = sessman.SessData.Session
local Windows = sessman.SessData.Windows
local Window = sessman.SessData.Window
local Tabs = sessman.SessData.Tabs
local Tab = sessman.SessData.Tab


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
    -- FIXME: implement an emulation of built-in session handler
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
        if not session_data or not session_data.name then w:error('Error in Sessiondata') return false end

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
        local sess = Session:parse(fh:read("*all"))
        io.close(fh)
        return sess
    end,

    -- Write tab data.
    write = function (name, sess, force)
        -- FIXME: sanitize Name
        assert(string.find(name, "/") == nil, "Session name may not contain '/'")
        if not lfs.attributes(session.path) then lfs.mkdir(session.path) end
        local sfile = file(session.path,name) -- will save to path/name
        local age = os.exists(sfile) and "old" or "new"
        if age == "old" and not force then return false end
        local fh = io.open(sfile, "w")
        if fh then 
            fh:write(sess:dump())
        else
            return false
        end
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
                    local curr_sess = session.copy_curr()
                    -- FIXME actually store sess to file

                    -- clear tabs from current window
                    -- FIXME get the length properly # is bogus
                    local numwin = #window.bywidget + 1
                    for _,w in pairs(window.bywidget) do 
                        if numwin > 1 then
                            w:close()
                            numwin = numwin - 1
                        else
                            while w.tabs:count() ~= 1 do
                                w:close_tab(nil, true)
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
        -- local w = w
        if sess_data and w then -- load new tabs
            for wi, win in pairs(sess_data.win) do
                for ti, tab in pairs(win.tab) do
                    -- print("loading tab with:" .. tab.uri .. tostring(tab.hist))
                    w:new_tab(tab.hist)
                end
            end
        end
    end,

    -- Copy current Session
    copy_curr = function()
        local self = Session:new()
        -- get all active windows
        local wins = {}
        for _,w in pairs(window.bywidget) do table.insert(wins, w) end

        -- setup basic info for session
        self.name  = "Current"
        
        self.ctime = os.date('%y%m%d_%H%M')
        self.mtime = os.date('%y%m%d_%H%M')
        self.win   = Windows:new()
        self.sync  = false

        -- iterate over windows and add tabs to self
        for wi, w in ipairs(wins) do
            local current = w.tabs:current()
            self.win[wi] = Window:new()
            self.win[wi].currtab = current
            self.win[wi].tab = Tabs:new()
            for ti, tab in ipairs(w.tabs.children) do
                self.win[wi].tab[ti] = Tab:new({uri= tab.uri, title=tab.title, hist=tab.history})
            end
        end
        return self
    end,

}

-------------------------
-- JS interface functions
-------------------------

function get()
    local Sessions = {}
    Sessions[1] = session.copy_curr()
    for sessfile in lfs.dir(session.path) do
        if not ( sessfile == "." or sessfile == ".." ) then
            table.insert(Sessions, session.read(sessfile))
        end
    end 

    return Sessions
end

function add(sessname, overwrite)
    w = currwin
    if ((not sessname) or sessname == "") then sessname=os.date('autosave_%y%m%d_%H%M') end 

    local sess = session.copy_curr()
    sess.name = sessname

    return session.store(w, sess,overwrite or false)
end

function loads(sessname)
    w = currwin
    -- FIXME: error handling when sessname not set
    if not sessname then w:error('No Sessionname specified.') return false end

    return session.sload(w, sessname,false)
end

export_funcs = {
    sessionman_add    = _M.add,
    sessionman_get    = _M.get,
    sessionman_load    = _M.loads,
    -- FIXME: implement a delete session operation
    -- sessionman_remove = remove,
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

--------------------
-- Key Bindings
--------------------

local key, buf = lousy.bind.key, lousy.bind.buf
add_binds("normal", {
--     buf("^gs$", "Open session manager in the current tab.",
--         function(w)
--             w:navigate(chrome_page)
--         end),
--
    buf("^gS$", "Open session manager in a new tab.",
        function(w)
            w:new_tab(chrome_page)
        end)
})

currwin = nil

--------------------
-- Commands
--------------------

local cmd = lousy.bind.cmd
add_cmds({
    cmd("sessionman", function (w)
            w:new_tab(chrome_page)
            -- FIXME a better way to get the current window is needed
            currwin = w
        end),
    cmd("loadsess", function (w,a,o)
            currwin = w

            name = a
            session.sload(w, name, not o.bang)
        end),
    cmd("savesess", function (w,a,o)
            currwin = w

            sessname = a or ""
            add(sessname, not o.bang)
        end),
})
