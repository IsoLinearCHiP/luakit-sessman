var dummy_data = ' [\
        { "name" : "Session 1", "windows" : [\
            { "title": "win1, urltitle 1", "url": ""},\
            { "title": "win1, urltitle 2", "url": ""},\
            { "title": "win1, urltitle 3", "url": ""}\
        ], "created" : "", "modified" : "", "sync" : "false"},\
        { "name" : "Session 2", "windows" : [\
            { "title": "win2, urltitle 1", "url": ""},\
            { "title": "win2, urltitle 2", "url": ""},\
            { "title": "win2, urltitle 3", "url": ""}\
        ], "created" : "", "modified" : "", "sync" : "false"},\
        { "name" : "Session 3", "windows" : [\
            { "title": "win3, urltitle 1", "url": ""},\
            { "title": "win3, urltitle 2", "url": ""},\
            { "title": "win3, urltitle 3", "url": ""}\
        ], "created" : "", "modified" : "", "sync" : "false"}\
    ]';

// returns the list of sessions stored by luakit
function sessionman_get() {
    'use strict';
    return dummy_data;
};

// load the selected session into luakit
function sessionman_load(sess_num) {
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
