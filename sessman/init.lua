---------------------------------------------------------------------------
-- @author IsoLinearCHiP <isolin.chip@gmail.com>
---------------------------------------------------------------------------

-- Grab environment we need
local util = require("lousy.util")

-- Grab what we need from the Lua environment
local table = table
local string = string
local io = io
local type = type
local realprint = print
local unpack = unpack
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
local new_mode = new_mode
local menu_binds = menu_binds
local completion = completion
local capi = {
    luakit = luakit,
    timer = timer
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

function print(...)
    for k,v in pairs(arg) do
        if type(v) ~= "string" then
            arg[k] = tostring(v)
        end
    end
    realprint(unpack(arg))
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
    assert(string.match(fname, "^[.][.]?$") == nil, "dont try anything on '.' or '..'")
    assert(string.find(fname, "/") == nil, "Session name may not contain '/'")
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

    -- Delete a session
    delete = function (name)
        -- FIXME: sanitize Name
        if not lfs.attributes(session.path) then return end
        local sfile = file(session.path,name)
        if not os.exists(sfile) then 
            return
        else
           return os.remove(sfile)
        end
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
                    for _,wtemp in pairs(window.bywidget) do 
                        if wtemp ~= w then
                            wtemp:close_win()
                        else
                            while wtemp.tabs:count() ~= 1 do
                                wtemp:close_tab(nil, false)
                            end
                        end
                    end
                    session.open(w,sess_data)
                else
                    session.open(nil,sess_data)
                end
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
        if sess_data then -- load new tabs
            for wi, win in pairs(sess_data.win) do
                w = w or window.new({"luakit://sessionman/"})
                w:close_tab(nil, false)
                for ti, tab in pairs(win.tab) do
                    -- print("loading tab with:" .. tab.uri .. tostring(tab.hist))
                    w:new_tab(tab.hist)
                end
                w = nil
            end
        end
    end,

    -- load sessions from sessionpath
    get_sessions = function (sessname)
        local Sessions = {}
        local sessname = sessname or ""
        for sessfile in lfs.dir(session.path) do
            if not ( sessfile == "." or sessfile == ".." ) then
                local sess = session.read(sessfile)
                if string.match(sess.name, sessname) then 
                    table.insert(Sessions, sess)
                end
            end
        end 

        return Sessions
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
    local Sessions = session.get_sessions()
    table.insert(Sessions, 1, session.copy_curr())

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

-- window specific state is stored here
local state = setmetatable({}, { __mode = "k" })

local key, buf = lousy.bind.key, lousy.bind.buf
add_binds("normal", {
--     buf("^gs$", "Open session manager in the current tab.",
--         function(w)
--             w:navigate(chrome_page)
--         end),
--
--     buf("^gS$", "Open session manager in a new tab.",
--         function(w)
--             w:new_tab(chrome_page)
--         end)
    buf("^gs$", "Display sessions and replace by default.",
        function(w)
            currwin = w

            if not state[w] then state[w] = {} end
            state[w].replace = true
            w:set_mode("sessionlist")
        end),

    buf("^gS$", "Display sessions and add by default",
        function(w)
            currwin = w

            if not state[w] then state[w] = {} end
            state[w].replace = false
            w:set_mode("sessionlist")
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
    cmd("sessload", function (w,a,o)
            currwin = w

            -- trim the string, since tab complete adds funky spaces
            local name = a:match("^%s*(.-)%s*$")
            session.sload(w, name, o.bang)
        end),
    cmd("sesssave", function (w,a,o)
            currwin = w

            -- trim the string, since tab complete adds funky spaces
            local name = a:match("^%s*(.-)%s*$") or ""
            add(name, o.bang)
        end),
    cmd("sessremove", function (w,a,o)
            currwin = w

            -- trim the string, since tab complete adds funky spaces
            local name = a:match("^%s*(.-)%s*$") or ""
            -- FIXME: add some userfeedback
            session.delete(name)
        end),
    cmd("sesslist", function (w,a,o)
            currwin = w

            if not state[w] then state[w] = {} end
            state[w].replace = (o.bang == true)
            w:set_mode("sessionlist")
        end),
})

-- FIXME: add interactive list for sessionnames
-- Add mode to display all sessions in an interactive menu.
function build_sessmenu(sessname,left)
    local sessions = session.get_sessions(sessname)
    if not sessions then return end

    local left = left or ""
    -- Build session list
    local rows = {{ "", "Name", "Created", "Modified", "Win/Tabs", "Sync", title = true }}
    for _, s in ipairs(sessions) do
        local function name()
            return s.name
        end
        local function ctime()
            return s.ctime
        end
        local function mtime()
            return s.mtime
        end
        local function tabcount()
            tabcount = 0
            for _,wi in ipairs(s.win) do tabcount = tabcount + #wi.tab end
            return #s.win .. "/" .. tabcount
        end
        local function sync()
            return tostring(s.sync)
        end
        table.insert(rows, { "", name, ctime, mtime, tabcount, sync, sess = s, left = left .. name() })
    end
    
    return rows
end

new_mode("sessionlist", {
    enter = function (w)
        -- Build session list
        local rows = build_sessmenu()
        w.menu:build(rows)
        local helpstr = "j/k to move, o open, w append, d delete"
        helpstr = (state[w].replace and "[O] ENT open, S-ENT append, " or "[W] ENT append, S-ENT open, ") .. helpstr -- prepend the mode
        w:notify(helpstr, false)
    end,

    leave = function (w)
        w.menu:hide()
        state[w].replace = nil
    end,
})

-- Add additional binds to session menu mode.
-- local key = lousy.bind.key
add_binds("sessionlist", lousy.util.table.join({
    -- Delete session
    key({}, "d", "Delete a session from disk.",
        function (w)
            local row = w.menu:get()
            if row and row.sess then
                session.delete(row.sess.name)
                w:set_mode("sessionlist")
            end
        end),

--     -- Rename session
--     key({}, "r", function (w)
--         local row = w.menu:get()
--         if row and row.dl then
--             -- FIXME: rename the session
--         end
--         -- HACK: Bad way of refreshing session list to show new items
--         -- (I.e. the new session after the rename)
--         w:set_mode("sessionlist")
--     end),

    key({}, "w", "Open a session appending to the current one.",
        function (w)
            local row = w.menu:get()
            if row and row.sess then
                session.sload(w, row.sess.name, false)
                w:set_mode()
            end
        end),
    key({}, "o", "Open a session replacing the current one.",
        function (w)
            local row = w.menu:get()
            if row and row.sess then
                session.sload(w, row.sess.name, true)
                w:set_mode()
            end
        end),
    key({}, "Return", "Open a session, maybe replacing the current one.",
        function (w)
            local row = w.menu:get()
            if row and row.sess then
                session.sload(w, row.sess.name, state[w].replace)
                w:set_mode()
            end
        end),
    key({"Shift"}, "Return", "Open a session, maybe replacing the current one.",
        function (w)
            local row = w.menu:get()
            if row and row.sess then
                session.sload(w, row.sess.name, not state[w].replace)
                w:set_mode()
            end
        end),

    -- Exit menu
    key({}, "q", function (w) w:set_mode() end),

}, menu_binds))

-- FIXME: add tab-completion
-- dont tab-complete bookmarks or history on listsess
completion.order[2] = function(state) if string.match(state.left, "^sess(%S+)%s") then return else return completion.funcs.history(state) end end
completion.order[3] = function(state) if string.match(state.left, "^sess(%S+)%s") then return else return completion.funcs.bookmarks(state) end end

table.insert(completion.order, function(state) 
        -- Find word under cursor (also checks not first word)
        local term = string.match(state.left, "%s(%S+)$")
        local cmd = string.match(state.left, "^sess(%S+)%s")
        if not cmd or not term then return end

        -- Strip last word (so that we can append the completion uri)
        local left = ":" .. string.sub(state.left, 1,
            string.find(state.left, "%s(%S+)$"))

        local rows = build_sessmenu(term, left)
        return rows
    end)

-- FIXME: shutdown interuption if session not saved?
-- capi.luakit.add_signal("can-close", function ()
--     return "reason not to shutdown"
-- end)

-- FIXME: Add some visual feedback to the statusbar?
-- like sessionname / saved status of the session
-- window.init_funcs.session_status = function (w)
--     local r = w.sbar.r
--     r.session = capi.widget{type="label"}
--     r.layout:pack(r.session)
--     r.layout:reorder(r.session, 1)
--     -- Apply theme
--     local theme = lousy.theme.get()
--     r.session.fg = theme.session_sbar_fg
--     r.session.font = theme.session_sbar_font
-- end
-- 
-- local status_timer = capi.timer{interval=1000}
-- status_timer:add_signal("timeout", function ()
--     -- if I want to stop the visual update...
--     if something then status_timer:stop() end
-- 
--     _M.emit_signal("status-tick", SOMEINFO)
-- end)
