var dummy_data = [
        { "id"    : "CURRENT",
          "name"  : "Current Sessoin",
          "ctime" : "",
          "mtime" : "",
          "sync"  : false,
          "win"   : [
              { "currtab" : 1, "tab" : [ 
                      { title : "win1,tab1", uri : "http://1" },
                      { title : "win1,tab2", uri : "http://2" },
                      { title : "win1,tab3", uri : "http://3" },
              ] },
              { "currtab" : 2, "tab" : [ 
                      { title : "win2,tab1", uri : "http://1" },
                      { title : "win2,tab2", uri : "http://2" },
              ] },
          ]
        },
        { "id"    : "SomeCrypticHash",
          "name"  : "A saved session",
          "ctime" : "2000-01-01 00:00:01",
          "mtime" : "2012-12-31 23:59:59",
          "sync"  : false,
          "win"   : [
              { "currtab" : 1, "tab" : [ 
                      { title : "win1,tab1", uri : "http://1" },
                      { title : "win1,tab2", uri : "http://2" },
                      { title : "win1,tab3", uri : "http://3" },
              ] },
              { "currtab" : 2, "tab" : [ 
                      { title : "win2,tab1", uri : "http://1" },
                      { title : "win2,tab2", uri : "http://2" },
                      { title : "win2,tab3", uri : "http://3" },
              ] },
              { "currtab" : 3, "tab" : [ 
                      { title : "win3,tab1", uri : "http://1" },
                      { title : "win3,tab2", uri : "http://2" },
                      { title : "win3,tab3", uri : "http://3" },
              ] }
          ]
        }
    ];

// returns the list of sessions stored by luakit
function sessionman_get() {
    'use strict';
    return dummy_data;
};

// load the selected session into luakit
function sessionman_load(sess_id) {
    'use strict';
    alert("luakit would now load session " + sess_num);
    update_sessionlist();
};

// save the currently active session
function sessionman_add() {
    'use strict';
    alert("luakit would now add the current session.");
    update_sessionlist();
};

// delete the selected session
function sessionman_del(sess_num) {
    'use strict';
    alert("luakit would now delete session " + sess_num);
    update_sessionlist();
};
