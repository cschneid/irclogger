module IRCLogger
  module Helpers
    def relative_day(day) 
      case day
      when "today": Date.today.strftime("%Y-%m-%d")
      when "yesterday": (Date.today - 1).strftime("%Y-%m-%d")
      else Date.today.strftime("%Y-%m-%d")
      end
    end


    ## Stolen from rails
    AUTO_LINK_RE = %r{
          	(                          # leading text
          	  <\w+.*?>|                # leading HTML tag, or
          	  [^=!:'"/]|               # leading punctuation, or
          	  ^                        # beginning of line
          	)
          	(
          	  (?:https?://)|           # protocol spec, or
          	  (?:www\.)                # www.*
          	)
          	(
          	  [-\w]+                   # subdomain or domain
          	  (?:\.[-\w]+)*            # remaining subdomains or domain
          	  (?::\d+)?                # port
          	  (?:/(?:(?:[~\w\+@%=\(\)-]|(?:[,.;:'][^\s$])))*)* # path
          	  (?:\?[\w\+@%&=.;-]+)?     # query string
          	  (?:\#[\w\-]*)?           # trailing anchor
          	)
          	([[:punct:]]|<|$|)       # trailing text
                 }x unless const_defined?(:AUTO_LINK_RE)

    # Turns all urls into clickable links.  If a block is given, each url
    # is yielded and the result is used as the link text.
    def auto_link_urls(text)
      text.gsub(AUTO_LINK_RE) do
        all, a, b, c, d = $&, $1, $2, $3, $4
        if a =~ /<a\s/i # don't replace URL's that are already linked
          all
        else
          text = b + c
          text = yield(text) if block_given?
          %(#{a}<a href="#{b=="www."?"http://www.":b}#{c}">#{text}</a>#{d})
        end
      end
    end
  end # End Module Helpers
end # End Module IRCLogger
