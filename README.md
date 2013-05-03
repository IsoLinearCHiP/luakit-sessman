About
=====
A sessionmanager for luakit.

Provides a more flexible sessionmanagement than the default provided by the current version of luakit.


Installation
============

Change to a directory where you want to keep the 'distribution' files. For example ```~/soft/``` .

```bash
cd ~/soft
```

Then clone the repository and create a symlink to your luakit config folder.

```bash
git clone git://github.com/IsoLinearCHiP/luakit-sessman.git
ln -s `pwd`/luakit-sessman/sessman ~/.config/luakit/sessman
```

Next edit your ```~/.config/luakit/rc.lua``` file and add ```require "sessman"``` in the "Optional user script loading" section

**Attention**
If you add it after ```require session``` the internal sessionmanagement (ZZ, :restart, etc) wont work. This is semi-intentional as this extention is meant to eventually be a drop-in replacement, however that part is not finished yet.

**Attention**
If you changed anything about the order of the tab-completion module (or for that matter probably anything about the tab-completion) things will likely be broken, as I am doing some funky stuff with the complete module, to get the tab-completion to work with the session list. I will add an option to disable interfering with the tabcomplete module at a later time.


Usage
=====

By default there are two keybindings added:
* ```gs``` : Opens the sessionmenu - with enter defaulting to replace current session
* ```gS``` : Opens the sessionmenu - with enter defaulting to append to current session

By default there are four commands added:
* ```:sesslist```        : Opens the sessionlist menu
* ```:sesssave [name]``` : Saves the current session to under a given name
* ```:sessload name```   : Loads the session of the given name
* ```:sessremove name``` : Deletes the session with the given name

Sessionlist Menu
----------------

The sessionlist menu has a few keybindings of its own in addition to the usual menu keybindings:

* ```Enter```   : Depending on whether ```:sesslist``` was used with a bang ("!"), the default action is either replace or append. See the status Line for an indication of which is the case.
* ```S-Enter``` : Depending on whether ```:sesslist``` was used with a bang ("!"), the default action is either append or replace. See the status Line for an indication of which is the case.
* ```o```       : Reguardless of the default action (bang or not) replaces the current session.
* ```w```       : Reguardless of the default action (bang or not) appends to the current session.
* ```D```       : Deletes the session. **Attention** this is a capital D to make accidental deletion unlikely.

Commands
--------

Use ```:sesslist``` to open the sessionlist menu. If a bang ("!") is added to the command, the default behaviour of Enter is changed from replace to append.

Use ```:sesssave [name]``` to save the current session under the given name (if you dont provide a name, "autosave" and a datetime will be used). In order to replace an existing session you need to add a bang ("!") to the command.

Use ```:sessload name``` to load a sessions. If you add a bang ("!") to the command the current session is replaced, rather than appended to.

Use ```:sessremove name``` to delete the session of the given name.

All these commands offer tab-completion of the argument, if you start typing letters from the sessionname.


Attributions:
=============
* sess_saver.lua : http://sprunge.us/KYDc, from user joggle in #luakit
* json.lua : https://github.com/craigmj/json4lua/raw/master/json4lua/json/json.lua
* luaunit: https://github.com/luaforge/luaunit/blob/master/luaunit.lua
* last but certainly not least, luakit itself, most of the interface code is refactored from existing modules, like downloads, tabcomplete, binds, proxy, etc.
