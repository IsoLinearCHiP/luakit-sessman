
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

stylesheet = [===[
// this space intentionally left blank
]===]


-- io.input("session_manager.html")
-- local html = io.read("*all")

local html = [==[
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Debug Introspection</title>
    <style type="text/css">
        /* {%stylesheet} */
        * {
            font-size: 12pt;
        }

        /* general settings for multicol table */
        table.multicol {
        	margin: 0;
        	padding: 0;
            width: 100%;
            border-spacing: 0px;
            line-height: 16pt;
        }
        table.multicol td {
        	margin: 0 1px;
        	padding: 0 3px;
        }
        table.multicol th {
        	border-left: 1px solid black;
        	border-right: 1px solid black;
        	border-bottom: 1px solid black;
        	border-collapse: collapse;
        	margin: 0 1px;
        	padding: 0 3px;
        	text-align: left;
        }

        /* general settings for selectable table */
        table.selectable>tbody>tr.selected {
            background: #316AC5;
            color: #FFF;
        }
        table.selectable>tbody>tr.hover {
            background: #66CCFF;
            color: #FFF;
        }

        /* styling for the session box */
        div#tbl-list {
            width: 80%;
            height: 88pt;
            vertical-align: middle;
            margin: 0 auto;
            border: 1px solid black;
            overflow: auto;
            margin-bottom: 10px;
        }

        /* styling for the window box */
        div#window-list {
            width: 80%;
            height: 88pt;
            vertical-align: middle;
            margin: 0 auto;
            border: 1px solid black;
            overflow: auto;
        }
        /* styling for the window box */
        div#controls {
            width: 80%;
            vertical-align: middle;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div id="tbl-list"><ul id="sessions"></ul></div>
    <div id="controls">
        <input type="text" id="variable" value="_G" />
        <input type="button" id="select-button" value="Select" />
    </div>
</body>
]==]

local main_js = [=[
function build_tbllist(tbldata) {
    'use strict';
    var tbl, thead, tbody, tr, th, td;
    tbl = document.createElement("table");
    $(tbl).addClass("multicol");
    $(tbl).addClass("selectable");

    // setup header
    thead = document.createElement("thead");
    tr = document.createElement("tr");

    $(document.createElement("th")).html("key").appendTo(tr);
    $(document.createElement("th")).html("value").appendTo(tr);
    $(document.createElement("th")).html("type").appendTo(tr);
    $(thead).append(tr);

    $(tbl).append(thead);

    tbody = document.createElement("tbody");
    for ( var i=0; i<tbldata.length; i++) {
        tr = document.createElement("tr");
        $(tr).attr("data-key", tbldata[i].key);

        $(document.createElement("td")).html(tbldata[i].key).appendTo(tr);
        $(document.createElement("td")).html(tbldata[i].value.toString()).appendTo(tr);
        $(document.createElement("td")).html(tbldata[i].type).appendTo(tr);
        $(tbody).append(tr);
    }

    $(tbl).append(tbody);
    return tbl;
};

function update_clickhandlers() {
    // $('div#session-list table tbody tr').hover(
    $('table.selectable tbody tr').hover(
        function() { $(this).addClass('hover'); },
        function() { $(this).removeClass('hover'); }
    ).click(function() {
        // single select
        $("div#session-list table tbody tr.selected").removeClass('selected');
        $(this).addClass('selected');

        var varname = $("#variable").attr("value");
        varname += "." + $(this).attr("data-key");
        $("#variable").attr("value", varname);
        update_tbllist(varname);
    });
};

function update_tbllist(varname) {
    'use strict';
    var tbl = jQuery.parseJSON(debug_dir(varname));
    var tbl_html = build_tbllist(tbl);
    $("#tbl-list").html(tbl_html);

    update_clickhandlers();
};
$(document).ready(function () { 
    'use strict';
    // var session_list = $("#session-list"), window_list = $("#window-list");

    update_tbllist("_G");
    $("#select-button").click(function() {update_tbllist($("#variable").attr("value"))});
});
]=]

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
    	out = out .. string.format('{ "key" : "%s", "value" : "%s", "type" : "%s" }', tostring(k), tostring(v), tostring(type(v)))
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
