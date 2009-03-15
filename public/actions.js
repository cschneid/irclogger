
$(document).ready(function() {
  $("#links a").click(function() {
    // Content
    // Is gist?
    if ($(this).is("[href*='gist.github.com']")) {
      var url = $(this).attr("href");
      // Launch lightbox
      $("#dialog").html(url);
      $("#dialog").dialog();
    }
  });
})

