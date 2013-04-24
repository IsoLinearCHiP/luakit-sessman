local table = table
local string = string
local io = io
local print = print
local pairs = pairs
local ipairs = ipairs
local assert = assert
local setmetatable = setmetatable
local tostring = tostring
local debug = debug

-- local json = require("sessman.json")
-- FIXME: should work?, but doesnt
require("sessman.json")
require("sessman.util")
local json = json
local dir = dir
-- does work

module("sessman.SessData")
---------------------------------------------
-- OOP interface to windows tabs and sessions
---------------------------------------------

Tab = {
    -- __index = { uri = "", title = "", hist = {} },
    -- FIXME: should init hist in new()

    __tostring = function(self)
        -- print("Tab tostring")
        local title = self.title or "No Title given"
        local uri = self.uri or "URI missing"
        return "Tab { title: " .. title .. " , uri: " .. uri .. " , hist: " .. dir(self.hist) .. " }"
        -- return "Tab { title: " .. self.title .. " , uri: " .. self.uri .. " , hist: " .. dir(self.hist) .. " }"
    end,

    new = function(self, o)
        def = { uri = "", title = "", hist = {} }
        -- local o = o or {}
        -- print("creating new Tab")
        return setmetatable(o or def, Tab)
    end,

    clone = function(self)
        local res = Tab:new()

        res.uri   = self.uri
        res.title = self.title
        res.hist  = self.hist -- FIXME should prob clone this too

        return res
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
        for i,s in ipairs(self) do -- FIXME ipairs might be wrong here
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

        for ti,t in ipairs(self) do -- FIXME ipairs might be wrong here
            res[ti] = t:clone()
        end

        return res
    end,
}

Window = {
    -- __index = { currtab = 0, tab = {} },
    -- FIXME: should init tab in new()

    __tostring = function(self)
        -- print("Window tostring")
        return "Window { currtab: " .. self.currtab .. " , tabs: " .. tostring(self.tab) .. " }"
    end,

    new = function(self, o)
        def = { currtab = 0, tab = Tabs:new() }
        -- local o = o or {}
        -- print("creating new Window")
        return setmetatable(o or def, Window)
    end,

    clone = function(self)
        local res = Window:new()

        res.currtab = self.currtab
        res.tab     = self.tab:clone()

        return res
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
        for i,s in ipairs(self) do -- FIXME ipairs might be wrong here
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

        for wi,w in ipairs(self) do -- FIXME ipairs might be wrong here
            res[wi] = w:clone()
        end

        return res
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
        local def = { name = "", ctime = nil, mtime = nil, win = Windows:new(), sync = false, }
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
            self.win   = Windows:new(data.win)
        end
        return self
    end,

    clone = function(self)
        local res = Session:new()

        res.name  = self.name
        res.ctime = self.ctime
        res.mtime = self.mtime
        res.win   = self.win:clone()

        return res
    end,
}
Session.__index = Session -- dies ist die "mach mal das OOP heile Zeile"
