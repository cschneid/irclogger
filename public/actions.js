
$(document).ready(function() {
  $("#links a[href*=gist.github.com]").click(function() {
    $("body").append("<div id='dialog'></div>");
    var url = $(this).attr("href");
    // Launch lightbox
    $("#dialog").html("<script src='" + url + ".js'></script>");
    $("#dialog").dialog({
    	title: url,
	close: function(ev, ui) { $(this).remove(); } 
    });
    return false;
  });
})

