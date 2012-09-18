
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
local assert = assert
local setmetatable = setmetatable
local type = type
local tostring = tostring
local _G = _G
local debug = debug

-- Grab the luakit environment we need
local lousy = require("lousy")
local chrome = require("chrome")
-- local markdown = require("markdown")
local add_binds = add_binds
local add_cmds = add_cmds
local webview = webview
local capi = {
    luakit = luakit
}

-- Advanced sessionmanager inspired by SessionManager Extension to Firefox
module("mydebug")

function getcwd()
    local path = debug.getinfo(1).short_src
    local dir,_ = string.gsub(path, "^(.+/)[^/]+$", "%1")
    return dir
end


stylesheet = [===[
// this space intentionally left blank
]===]


-- io.input("session_manager.html")
-- local html = io.read("*all")

local html = lousy.load(getcwd() .. "debug.html")

local main_js = lousy.load(getcwd() .. "debug.js")

function dir(x) 
    -- print("dir'ing " .. x .. "\n")
    local tbl = _G
    if string.find(x, "[.]") ~= nil then 
        local path = {}
    	util.string.split(x, '[.]', path)
        -- print(table.concat(path, ','))
        for _,v in pairs(path) do 
        	tbl = tbl[v]
        end
    else
    	tbl = tbl[x]
    end

    local out = "" 
    for k,v in pairs(tbl) do 
    	if string.len(out) > 0 then out = out .. ",\n" end
    	local strrepr = tostring(v)
    	-- FIXME: need to check for more 'bad' characters for jsonification, should write a function for json marshaling
    	strrepr = string.gsub(strrepr, "\n", "\\n")
    	strrepr = string.gsub(strrepr, '"', '\\"')
    	out = out .. string.format('{ "key" : "%s", "value" : "%s", "type" : "%s" }', tostring(k), strrepr, tostring(type(v)))
    end
    -- print("[\n" .. out .. "\n]")
    return "[\n" .. out .. "\n]"
end

function inspect(x) 
end

-- :lua (function(w) w.pprint = function(x) local out = ""; for k,v in pairs(x) do out = out .. tostring(k) .. " : " .. "{ " .. tostring(v) .. " }\n" end return out end end)(w)
function pprint(x) 
    local out = "" 
    for k,v in pairs(x) do 
    	out = out .. tostring(k) .. " : " .. "{ " .. tostring(v) .. " }\n" 
    end
    return out
end


export_funcs = {
    debug_dir     = _M.dir,
    -- debug_inspect = _M.inspect,
    -- debug_pprint  = _M.pprint,
}

chrome.add("debug", function (view, meta)
    local uri = "luakit://debug/"

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

        -- Double check that we are where we should be
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

        -- Load main luakit://debug/ JavaScript
        local _, err = view:eval_js(main_js, { no_return = true })
        assert(not err, err)
    end

    view:add_signal("load-status", on_first_visual)
end)

chrome_page = "luakit://debug/"

local key, buf = lousy.bind.key, lousy.bind.buf
add_binds("normal", {
    buf("^gd$", "Open session manager in the current tab.",
        function(w)
            w:navigate(chrome_page)
        end),

    buf("^gD$", "Open session manager in a new tab.",
        function(w)
            w:new_tab(chrome_page)
        end)
})

local cmd = lousy.bind.cmd
add_cmds({
    cmd("debug", function (w)
            w:new_tab(chrome_page)
        end),
})
