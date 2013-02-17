// FIXME sessions is global atm, probably not necisarry
var sessions;

function build_sessionlist(sessions) {
    'use strict';
    var tbl, thead, tbody, tr, th, td;
    tbl = document.createElement("table");
    $(tbl).addClass("multicol");
    $(tbl).addClass("selectable");

    // setup header
    thead = document.createElement("thead");
    tr = document.createElement("tr");

    //2dwi$($xi)Jdt.$xJdt.f(iTofhrr0w
    $(document.createElement("th")).html("Name").appendTo(tr);
    $(document.createElement("th")).html("Created").appendTo(tr);
    $(document.createElement("th")).html("Modified").appendTo(tr);
    $(document.createElement("th")).html("Sync?").appendTo(tr);
    $(document.createElement("th")).html("#Windows,Tabs").appendTo(tr);
    $(thead).append(tr);

    $(tbl).append(thead);

    tbody = document.createElement("tbody");
    for ( var i=0; i<sessions.length; i++) {
        tr = document.createElement("tr");
        $(tr).attr("data-sess-id", i);

        //2dwi$($xi)Jdt.$xJdt.f(iTofdrr0w
        $(document.createElement("td")).html(sessions[i].name).appendTo(tr);
        $(document.createElement("td")).html(sessions[i].ctime).appendTo(tr);
        $(document.createElement("td")).html(sessions[i].mtime).appendTo(tr);
        $(document.createElement("td")).html(sessions[i].sync).appendTo(tr);
        // count tabs
        var tabnum = 0;
        // alert(JSON.stringify(sessions[i].win[0]))
        for ( var j=0; j<sessions[i].win.length; j++) { tabnum += sessions[i].win[j].tab.length };
        $(document.createElement("td")).html("".concat(sessions[i].win.length, ", ", tabnum)).appendTo(tr);
        $(tbody).append(tr);
    }

    $(tbl).append(tbody);
    return tbl;
};

function build_windowlist(windows) {
    'use strict';
    var tbl, thead, tbody, tr, th, td;
    var sess, win, tab, li, span;

    sess = $(document.createElement("ul")).attr("class", "windows");

    for ( var i=0; i<windows.length; i++) {
        win = $(document.createElement("ul")).attr("class", "tabs");

        for ( var j=0; j<windows[i].tab.length; j++) {
            li = $(document.createElement("li")).attr("class", "tab");
            $(document.createElement("span")).attr("class", "title").html(windows[i].tab[j].title).appendTo(li);
            $(document.createElement("span")).attr("class", "uri").html(windows[i].tab[j].uri).appendTo(li);
            $(li).attr("data-tab-id", j);
            $(li).appendTo(win);
        };

        li = $(document.createElement("li")).attr("class", "window").html("Window " + i).append(win);
        $(li).attr("data-win-id", i).appendTo(sess);
    }

    return sess;
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
        // multi select
        // if ($(this).attr('class').indexOf('selected') > -1) {
        //     $(this).removeClass('selected');
        // }
        // else {
        //     $(this).addClass('selected');
        // }

        var sess_id = $(this).attr("data-sess-id");
        update_windowlist(sessions[sess_id]["win"]);
    });
};

function update_windowlist(window_list) {
    'use strict';
    var win_html = build_windowlist(window_list);
    $("#window-list").html(win_html);
};

function update_sessionlist() {
    'use strict';
    // sessions = jQuery.parseJSON(sessionman_get());
    sessions = sessionman_get();
    var sess_html = build_sessionlist(sessions);
    $("#session-list").html(sess_html);

    update_clickhandlers();
    // setup an empty window list, since nothing is selected yet
    update_windowlist([]);
};
$(document).ready(function () { 
    'use strict';
    // var session_list = $("#session-list"), window_list = $("#window-list");

    update_sessionlist();
    $("#select-button").click(function() {sessionman_load($("#session-list tr.selected").attr("data-sess-id"))});
    $("#add-button").click(function() {sessionman_add();});
    $("#delete-button").click(function() {sessionman_del($("#session-list tr.selected").attr("data-sess-id"))});
});
