
$(document).ready(function() {
  $("#links a[href*=gist.github.com]").click(function() {
    var url = $(this).attr("href");
    // Launch lightbox
    $("#dialog").html(url);
    $("#dialog").dialog();
    return false;

    return true;
  });
})

