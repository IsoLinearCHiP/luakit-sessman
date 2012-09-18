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
    $("#variable").attr("value", varname)

    update_clickhandlers();
};

function cssSizeToNum(csssize) {
    return parseInt(csssize.substr(0,csssize.length-2));
};

function onResize() {
	'use strict';

    var marginheight = cssSizeToNum($("#tbl-list").css("margin-top")) + cssSizeToNum($("#tbl-list").css("margin-bottom"));
    var borderheight = cssSizeToNum($("#tbl-list").css("border-top-width")) + cssSizeToNum($("#tbl-list").css("border-bottom-width"));
    var paddingheight = cssSizeToNum($("#container").css("padding-top")) + cssSizeToNum($("#container").css("padding-bottom"));
    var height = marginheight + borderheight + paddingheight;
    $("#tbl-list").height($("body").height()-$("#controls").height()-height);
};

$(document).ready(function () { 
    'use strict';
    // var session_list = $("#session-list"), window_list = $("#window-list");

    $("#select-button").click(function() {update_tbllist($("#variable").attr("value"))});
    $("#back-button").click(function() {
    	var path = $("#variable").attr("value");
    	var i = path.lastIndexOf(".");
    	if (i > 0) { path = path.substr(0,i) };
    	
    	update_tbllist(path)
    });
    $(window).resize(onResize);

    onResize();
    update_tbllist("_G");
});
