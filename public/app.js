var irclogger = {
  shift: false
}

$(document).ready(function() {
  var hash = window.location.hash.substring(1)

  if (hash.length > 0) {
    $(document.body).addClass("highlight")

    if (hash.match(/^[0-9]/)) {
      var anchors = hash.split("-")
      highlightLines(anchors)
    }
    else {
      var anchors = hash.split(",")
      highlightNicknames(anchors)
    }

    if (anchors.length > 1) $("a[name='" + anchors[0] + "']")[0].scrollIntoView()
  }

  $("#log a[name]").click(function() {
    if (irclogger.shift) {
      var from = window.location.hash.substring(1).split("-")[0]
      var to = this.name
      highlightLines([from, to])
      window.location.hash = "#" + from + "-" + to
    }
    else {
      $("#log > div").removeClass("highlight")
      $(this).parent().addClass("highlight")
      window.location.hash = "#" + this.name
    }

    return false
  })

  $(document).keydown(function(e) {
    if (e.keyCode == 16) irclogger.shift = true
  })

  $(document).keyup(function(e) {
    if (e.keyCode == 16) irclogger.shift = false
  })
})

function highlightLines(range) {
  $(document.body).addClass("highlight")

  range = range.sort()

  var first = range[0]
  var last  = range[1] || range[0]

  $("#log a").each(function() {
    var $entry = $(this).parent()

    if (this.name >= first && this.name <= last) {
      $entry.addClass("highlight")
    }
    else {
      $entry.removeClass("highlight")
    }
  })
}

function highlightNicknames(nicknames) {
  nicknames = $.map(nicknames, function(nickname) {
    return "<" + nickname + ">"
  })

  $("#log .msg .nickname").each(function() {
    var $entry = $(this)

    $.each(nicknames, function() {
      var nickname = this

      if ($entry.text().indexOf(nickname) > 0) {
        $entry.parent().addClass("highlight")

        return
      }
    })
  })
}
