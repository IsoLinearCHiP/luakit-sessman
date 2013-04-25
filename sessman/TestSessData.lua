---------------------------------------------------------------------------
-- @author IsoLinearCHiP <isolin.chip@gmail.com>
---------------------------------------------------------------------------

require("sessman.luaunit")

TestSessData = {}

    function TestSessData:setUp()
        -- set up tests
        require("sessman.SessData")
        require("util")

        Session = sessman.SessData.Session
        Windows = sessman.SessData.Windows
        Window = sessman.SessData.Window
        Tabs = sessman.SessData.Tabs
        Tab = sessman.SessData.Tab
    end

    function TestSessData:test_01_Creation()
        -- print("Testing Class creation...")
        -- assert(Session:new(), "Session failed!")
        -- assert(Windows:new(), "Windows failed!")
        -- assert(Window:new(), "Window failed!")
        -- assert(Tabs:new(), "Tabs failed!")
        -- assert(Tab:new(), "Tab failed!")
        assertEquals( ( Session:new() ~= nil ), true ) -- "Session failed!"
        assertEquals( ( Windows:new() ~= nil ), true ) -- "Windows failed!"
        assertEquals( ( Window:new() ~= nil ), true ) -- "Window failed!"
        assertEquals( ( Tabs:new() ~= nil ), true ) -- "Tabs failed!"
        assertEquals( ( Tab:new() ~= nil ), true ) -- "Tab failed!"
    end

    function TestSessData:test_02_fromTable()
        assertEquals( type(Session:from_table(nil)), type(Session:new()) )
        assertEquals( type(Session:from_table({})), type(Session:new()) )

        local tbl = {}

        tbl = {
                name  = "",
                ctime = nil,
                mtime = nil,
                win   = {}
            }


        s1 = Session:from_table(tbl)
        s2 = Session:new()
        res , err = deepcompare(s1, s2, true, false)
        assertEquals( res or err , true )

        tbl = {
                name  = "",
                ctime = nil,
                mtime = nil,
                win   = {
                    [1] = {
                        currtab = 0,
                        tab = {
                            [1] = {
                                uri = "",
                                title = "",
                                hist = {}
                            },
                            [2] = {
                                uri = "",
                                title = "",
                                hist = {}
                            },
                        }
                    }
                }
            }
        s1 = Session:from_table(tbl)
        s2 = Session:new()
        -- s2.win[2] = Window:new()
        res , err = deepcompare(s1, s2, true, false)
        assertEquals( res or err , true )

        tbl = {
                name  = "",
                ctime = nil,
                mtime = nil,
                win   = {
                    [1] = {
                        currtab = 0,
                        tab = {
                            [1] = {
                                uri = "",
                                title = "",
                                hist = {}
                            },
                            [3] = {
                                uri = "about:blank",
                                title = "",
                                hist = {}
                            },
                        }
                    }
                }
            }
        s1 = Session:from_table(tbl)
        s2 = Session:new()
        -- s2.win[2] = Window:new()
        res , err = deepcompare(s1, s2, true, false)
        assertEquals( res or err , "/win/1/tab/3/uri/" )
    end

    function TestSessData:test_03_tostring()
        assertError( function() tostring(Session:from_table({})) end ) -- FIXME make tostring more robust
    end

    function TestSessData:test_04_SerDeser()
        -- print("Testing Serialize/Deserialize...")
        sess = Session:new()
        sess2 = Session:new()

        -- print(sess:dump())
        out = sess:dump()
        -- print(out)
        sess2:parse(out)
        -- print(sess2)

        assertEquals(deepcompare(sess, sess2, false, false), true) -- "Serialize/Deserialize failed"
        -- assert(deepcompare(sess, sess2, false), "Serialize/Deserialize failed")
    end

    function TestSessData:test_05_DeserSer()
        sess2 = {}
        sess2 = Session:new()
        -- print(sess2)
        fh = io.open("/home/chp/.local/share/luakit/sessions/test")
        -- print(fh)
        ins=fh:read("*all")
        -- print(ins)
        sess2 = Session:parse(ins)
        -- print(sess2)
        -- print(dir(sess2))
        out=sess2:dump()

        assertEquals(out, ins) -- "Deserialize->Serialize failed"
    end

-- TestSessData

LuaUnit:run()
