document.write = function(content) {
	$("#dialog").append(content);
}


$(document).ready(function() {
  $("#links a[href*=gist.github.com]").click(function() {
    var url = $(this).attr("href");

    $("body").append("<div id='dialog'></div>");

    $("#dialog").dialog({
    	title: url,
	width: 800,
        close: function(ev, ui) { $(this).remove(); } ,
	open: function(ev, ui) { $(this).html("<script src='" + url + ".js'></script>"); }
    });

    return false;
  });
})

