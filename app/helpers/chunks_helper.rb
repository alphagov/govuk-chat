module ChunksHelper
  def render_html_content(content)
    render "govuk_publishing_components/components/govspeak" do
      content.html_safe
    end
  end
end
