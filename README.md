About
=====
A sessionmanager for luakit.

Provides a more flexible sessionmanagement than the default provided by the current version of luakit.

Installation
============

Change to a directory where you want to keep the 'distribution' files. For example ~/soft/ .

```bash
cd ~/soft
```

Then clone the repository and create a symlink to your luakit config folder.

```bash
git clone git://github.com/IsoLinearCHiP/luakit-sessman.git; ln -s luakit-sessman/sessman ~/.config/luakit/sessman
```

Next edit your ~/.config/luakit/rc.lua file and add ```require "sessman"``` in the "Optional user script loading" section

**Attention**
If you add it after ```require session``` the internal sessionmanagement (ZZ, :restart, etc wont work), this is semi-intentional as this extention is meant to eventually be a dropin replacement, however that part is not finished yet.

Usage
=====

By default there is only one keybinding added ("gS") to start the HTML view of sessions. *Note* However this part is not fully operational at this point, it can be usefull to view the saved sessions, so it is activated allready.

Use ```:savesess [name]``` (if you dont provide a name, "autosave" and a datetime will be used) to save and ```:loadsess name``` to load a sessions. *Note* Tabs are currently all restored to one window, rather than seperate windows as saved in the session. This will be fixed later.

Deleting sessions is currently not implemented yet, just use standard file operations to delete the files from "~/.local/share/luakit/sessions/"


Attributions:
=============
* sess_saver.lua : http://sprunge.us/KYDc, from user joggle in #luakit
* json.lua : https://github.com/craigmj/json4lua/raw/master/json4lua/json/json.lua
* luaunit: https://github.com/luaforge/luaunit/blob/master/luaunit.lua
