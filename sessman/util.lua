---------------------------------------------------------------------------
-- @author IsoLinearCHiP <isolin.chip@gmail.com>
---------------------------------------------------------------------------

--------------------
-- utility functions
--------------------

--- Returns string representation of object obj
-- @return String representation of obj
function dir(obj,level)
    local s,t = '', type(obj)
    
    level = level or '  '

    if (t=='nil') or (t=='boolean') or (t=='number') or (t=='string') then
        s = tostring(obj)
        if t=='string' then
            s = '"' .. s .. '"'
        end
    elseif t=='function' then s='function'
    elseif t=='userdata' then s='userdata'
    elseif t=='thread' then s='thread'
    elseif t=='table' then
        s = '{'
        for k,v in pairs(obj) do
            local k_str = tostring(k)
            if type(k)=='string' then
                k_str = '["' .. k_str .. '"]'
            end
            s = s .. k_str .. ' = ' .. dir(v,level .. level) .. ', '
        end
        s = string.sub(s, 1, -3)
        s = s .. '}'
    end
    
    return s
end

-- deep compare values
-- originally from http://snippets.luacode.org/?p=snippets/Deep_Comparison_of_Two_Values_3
-- modified to return information where the difference occurs,
-- as well as adding the option to trace the compare
--   t1, t2: are required and are the values which are compared
--   ignore_mt: whether to ignore the __eq method of tables
--   verbose: if true prints debug information on the compare
--   path: used internally, should not be set by caller
function deepcompare(t1,t2,ignore_mt,verbose,path)
    local ty1 = type(t1)
    local ty2 = type(t2)
    local path = path or ""
    path = path .. "/"
    local _, level = string.gsub(path, "/", function() return nil end) -- count occurs of /
    local msg = nil
    if verbose then
        msg = function(str) print(string.rep(" ", level) .. str) end
    else
        msg = function(str) end --  dummy when verbose not set
    end

    msg("start compare:" .. path .. ", " .. level)

    if ty1 ~= ty2 then return false, path end

    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return (t1 == t2), path end

    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return (t1 == t2), path end

    for k1,v1 in pairs(t1) do
        msg("t1:" .. path .. k1)
        local v2 = t2[k1]
        if v2 ~= nil then
            res, err = deepcompare(v1,v2, ignore_mt, verbose, path .. k1)
            if not res then 
                return false, err
            end
        else
            return false, (path .. k1) 
        end
        msg("equals!")
    end
    for k2,v2 in pairs(t2) do
        msg("t2:" .. path .. k2)
        local v1 = t1[k2]
        if v1 ~= nil then
            res, err = deepcompare(v1,v2, ignore_mt, verbose, path .. k2)
            if not res then 
                return false, err
            end
        else
            return false, (path .. k2) 
        end
        msg("equals!")
    end
    msg("equals!")
    return true
end
