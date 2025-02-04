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
        <li>make voluntary <a id="foo" href="https://www.gov.uk/national-insurance/what-national-insurance-is">National Insurance</a> payments</li>
        <li>fill in a <a href="/tax-returns">Tax return</a> each tax year.</li>
        <li>this is <a href="#some-heading">an anchor tag</a>.</li>
      </ul>
    HTML
  end

  describe "#map_links_to_tokens" do
    it "replaces href attributes with tokens" do
      amended_html = described_class.new.map_links_to_tokens(html, "/exact-path")
      parsed_html = Nokogiri::HTML::DocumentFragment.parse(amended_html)
      links = parsed_html.css("a")

      expect(links.length).to eq(5)

      expect(links[0]["href"]).to eq("link_1")
      expect(links[0].text).to eq("Tax return")

      expect(links[1]["href"]).to eq("link_2")
      expect(links[1].text).to eq("Tax News")

      expect(links[2]["href"]).to eq("link_3")
      expect(links[2].text).to eq("National Insurance")

      # Duplicate link, so gets the same token as the first link
      expect(links[3]["href"]).to eq("link_1")
      expect(links[3].text).to eq("Tax return")

      expect(links[4]["href"]).to eq("link_4")
      expect(links[4].text).to eq("an anchor tag")
    end
  end

  describe "#map_link_to_token" do
    it "stores the link and returns the token" do
      mapper = described_class.new
      link = "/tax-returns"
      token = mapper.map_link_to_token(link)

      expect(token).to eq("link_1")
      expect(mapper.link_for_token(token)).to eq(link)
    end

    it "returns the same token if the link is already in the mapping" do
      mapper = described_class.new
      token = mapper.map_link_to_token("/tax-returns")

      expect(mapper.map_link_to_token("/tax-returns")).to eq(token)
    end
  end

  describe "#replace_tokens_with_links" do
    it "replaces token-based links with stored links that are absolute URIs" do
      mapper = described_class.new
      mapper.map_links_to_tokens(html, "/exact-path")

      source = <<~MARKDOWN
        # Tax

        Keep updated about [Tax News][1]

        If you work for yourself you need to fill in a [Tax return](link_1 "Tax return") each tax year.

        You can choose to stay registered to:

        * prove you're self-employed, for example to claim Tax-Free Childcare
        * make voluntary [National Insurance](link_3) payments
        * do something with an [anchor tag](link_4)

        [1]: link_2
      MARKDOWN

      output = mapper.replace_tokens_with_links(source)

      #  Ensure we can handle reference-style links
      expect(output)
        .to include("[Tax News][1]")
        .and include("[1]: https://www.test.gov.uk/tax-news")

      # Ensure we can handle a link with a title
      expect(output)
        .to include("[Tax return][2]")
        .and include("[2]: https://www.test.gov.uk/tax-returns \"Tax return\"")

      # Ensure we don't rewrite an existing absolute URL
      expect(output)
        .to include("[National Insurance][3]")
        .and include("[3]: https://www.gov.uk/national-insurance/what-national-insurance-is")

      expect(output)
        .to include("[anchor tag][4]")
        .and include("[4]: https://www.test.gov.uk/exact-path#some-heading")
    end

    it "replaces link text that has not been substituted" do
      mapper = described_class.new
      mapper.map_links_to_tokens(html, "/exact-path")

      markdown = <<~MARKDOWN
        Send a tax return ([link_1][1])

        [1]: link_1
      MARKDOWN

      output = mapper.replace_tokens_with_links(markdown)
      expect(output).to include("Send a tax return ([source][1])")
    end

    it "handles invalid URIs" do
      html = '<p>Send a tax return to <a href="mailto:<user@example.com>">us</a></p>'
      mapper = described_class.new
      mapper.map_links_to_tokens(html, "/exact-path")

      markdown = <<~MARKDOWN
        You should send a tax return to [us](link_1)
      MARKDOWN

      output = mapper.replace_tokens_with_links(markdown)
      expect(output).to include("You should send a tax return to [us](mailto:<user@example.com>)")
    end

    it "strips the trailing newlines" do
      expect(described_class.new.replace_tokens_with_links("Some text\n\n")).to eq("Some text")
    end

    it "strips out any links that are not in the mapping" do
      source = "Some text with a [link](link_1) and something that [looks like] a link (but is not). A link with [`code`](https://example.com)"

      output = described_class.new.replace_tokens_with_links(source).squish

      expect(output).to eq(
        "Some text with a link and something that \\[looks like\\] a link (but is not). A link with `code`",
      )
    end
  end

  describe "#link_for_token" do
    it "returns the link for a given token" do
      mapper = described_class.new
      mapper.map_links_to_tokens(html, "/exact-path")

      expect(mapper.link_for_token("link_1")).to eq("https://www.test.gov.uk/tax-returns")
    end

    it "returns nil if the token is not in the mapping" do
      mapper = described_class.new

      expect(mapper.link_for_token("link_1")).to be_nil
    end
  end
end
