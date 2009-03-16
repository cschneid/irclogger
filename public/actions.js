
var doc_write = "";

$(document).ready(function() {

  document.write = function(content) {
    doc_write += content;
  }

  $("#links a[href*=gist.github.com], #links a[href*=pastie.org]").click(function() {
    var url = $(this).attr("href");

    $("body").append("<div id='dialog'></div>");

    $("#dialog").dialog({
    	title: url,
	width: 900,
        close: function(ev, ui) { $(this).remove(); } ,
	open: function(ev, ui) { d = $(this);
			         d.html("<script src='" + url + ".js'></script>"); 
				 window.setTimeout(function(){d.html(doc_write);}, 1000);
			       }
    });

    return false;
  });
})

