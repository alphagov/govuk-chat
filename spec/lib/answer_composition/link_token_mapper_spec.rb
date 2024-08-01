RSpec.describe AnswerComposition::LinkTokenMapper do
  let(:html) do
    <<~HTML
      <h1>Tax</h1>
      <p>
        If you work for yourself you need to fill in a <a href="/tax-returns" title="Tax return" class="govuk-link">Tax return</a> each tax year.
        <abbr title="HMRC">HMRC</abbr> will then work out how much tax you need to pay.
      </p>
      <p>You can choose to stay registered to:</p>
      <ul>
        <li>get updated about <a href="/tax-news">Tax News</a></li>
        <li>prove you're self-employed, for example to claim Tax-Free Childcare</li>
        <li>make voluntary <a id="foo" href="/national-insurance/what-national-insurance-is">National Insurance</a> payments</li>
        <li>fill in a <a href="/tax-returns">Tax return</a> each tax year.</li>
      </ul>
    HTML
  end

  describe "#map_links_to_tokens" do
    it "replaces href attributes with tokens" do
      amended_html = described_class.new.map_links_to_tokens(html)
      parsed_html = Nokogiri::HTML::DocumentFragment.parse(amended_html)
      links = parsed_html.css("a")

      expect(links.length).to eq(4)

      expect(links[0]["href"]).to eq("link_1")
      expect(links[0].text).to eq("Tax return")

      expect(links[1]["href"]).to eq("link_2")
      expect(links[1].text).to eq("Tax News")

      expect(links[2]["href"]).to eq("link_3")
      expect(links[2].text).to eq("National Insurance")

      #  Duplicate link, so gets the same token as the first link
      expect(links[3]["href"]).to eq("link_1")
      expect(links[3].text).to eq("Tax return")
    end
  end

  describe "#replace_tokens_with_links" do
    it "replaces token-based links with stored links" do
      mapper = described_class.new
      mapper.map_links_to_tokens(html)

      source = <<~MARKDOWN
        # Tax

        Keep updated about [Tax News][1]

        If you work for yourself you need to fill in a [Tax return](link_1 "Tax return") each tax year.

        You can choose to stay registered to:

        * prove you're self-employed, for example to claim Tax-Free Childcare
        * make voluntary [National Insurance](link_3) payments

        [1]: link_2
      MARKDOWN

      output = mapper.replace_tokens_with_links(source).squish

      expect(output).to include("[Tax return](/tax-returns \"Tax return\")")
      expect(output).to include("[National Insurance](/national-insurance/what-national-insurance-is)")

      #  Ensure we can handle reference-style links
      expect(output).to include("[Tax News](/tax-news)")
    end

    it "strips the trailing newlines" do
      expect(described_class.new.replace_tokens_with_links("Some text\n\n")).to eq("Some text")
    end
  end

  it "strips out any links that are not in the mapping" do
    source = "Some text with a [link](link_1) and something that [looks like] a link (but is not). A link with [`code`](https://example.com)"

    output = described_class.new.replace_tokens_with_links(source).squish

    expect(output).to eq(
      "Some text with a link and something that \\[looks like\\] a link (but is not). A link with `code`",
    )
  end
end
