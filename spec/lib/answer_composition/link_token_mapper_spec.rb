RSpec.describe AnswerComposition::LinkTokenMapper do
  describe "#map_links_to_tokens" do
    it "replaces href attributes with tokens" do
      html = <<~HTML
        <h1>Tax</h1>
        <p>If you work for yourself you need to fill in a <a href="/tax-returns">Tax return</a> each tax year. <abbr title="HMRC">HMRC</abbr> will then work out how much tax you need to pay.</p>
        <p>But you can choose to stay registered to:</p>
        <ul>
          <li>prove you're self-employed, for example to claim Tax-Free Childcare</li>
          <li>make voluntary <a href="/national-insurance/what-national-insurance-is">National Insurance</a> payments</li>
          <li>fill in a <a href="/tax-returns">Tax return</a> each tax year.</li>
        </ul>
      HTML

      amended_html = described_class.new.map_links_to_tokens(html)
      parsed_html = Nokogiri::HTML::DocumentFragment.parse(amended_html)
      links = parsed_html.css("a")

      expect(links.length).to eq(3)

      expect(links[0]["href"]).to eq("link_1")
      expect(links[0].text).to eq("Tax return")

      expect(links[1]["href"]).to eq("link_2")
      expect(links[1].text).to eq("National Insurance")

      #  Duplicate link, so gets the same token as the first link
      expect(links[2]["href"]).to eq("link_1")
      expect(links[2].text).to eq("Tax return")
    end
  end
end
