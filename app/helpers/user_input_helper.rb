module UserInputHelper
  def escaped_simple_format(string, html_options = {})
    simple_format(html_escape(string), html_options)
  end
end
