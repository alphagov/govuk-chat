RSpec.describe Chunking::ContentItemParsing::StepByStepNavParser do
  let(:details) do
    {
      "step_by_step_nav" => {
        "steps" => steps,
        "title" => "Step by step nav title",
        "introduction" => [
          {
            "content" => "Should be the first bit of content.",
            "content_type" => "text/govspeak",
          },
          {
            "content" => "<p>Should be the first bit of content.</p>\n",
            "content_type" => "text/html",
          },
        ],
      },
    }
  end
  let(:steps) { [numbered_step] }
  let(:numbered_step) do
    {
      "title" => "A numbered step",
      "contents" => [
        {
          "text" => "This is a step with only a para.", "type" => "paragraph"
        },
      ],
    }
  end

  describe ".call" do
    let(:content_item) do
      build(
        :notification_content_item,
        schema_name: "step_by_step_nav",
        details:,
      )
    end

    it "parses the step_by_step_nav in the details hash into HTML content" do
      result = described_class.call(content_item)

      expected_html_content = <<~HTML
        <p>Should be the first bit of content.</p>
        <h2>A numbered step</h2>
        <p>This is a step with only a para.</p>
      HTML
     .strip

      chunk = result.first
      expect(result.length).to eq(1)
      expect(chunk)
        .to have_attributes(
          content_item:,
          html_content: expected_html_content,
          heading_hierarchy: [],
          chunk_index: 0,
          exact_path: content_item["base_path"],
        )
    end

    context "when the document contains a step with an unknown content type" do
      let(:steps) { [unknown_content_type_step] }
      let(:unknown_content_type_step) do
        {
          "title" => "An invalid step",
          "contents" => [
            {
              "text" => "Data cell", "type" => "td"
            },
          ],
        }
      end

      it "raises an error" do
        expect { described_class.call(content_item) }.to raise_error("Unknown content type: td")
      end
    end

    context "when the document contains a step with a list" do
      context "and the list style is not 'choice'" do
        let(:step_with_list) do
          {
            "title" => "A step with a list of ordered links",
            "contents" => [
              {
                "text" => "This step contains a non-bulleted list.", "type" => "paragraph"
              },
              {
                "type" => "list",
                "contents" => [
                  { "href" => "/link-1", "text" => "Link 1", "context" => "rendered in span" },
                  { "href" => "/link-2", "text" => "Link 2" },
                  { "href" => "/link-3", "text" => "Link 3" },
                  { "text" => "Item without link" },
                  { "text" => "Item without link", "context" => "but has context (oddly)" },
                ],
              },
            ],
          }
        end
        let(:steps) { [step_with_list] }

        it "constucts an ordered list based on the links contained in the list" do
          chunk = described_class.call(content_item).first

          expected_html_content = <<~HTML
            <p>Should be the first bit of content.</p>
            <h2>A step with a list of ordered links</h2>
            <p>This step contains a non-bulleted list.</p>
            <ol><li><a href="/link-1">Link 1</a> <span>rendered in span</span></li>
            <li><a href="/link-2">Link 2</a></li>
            <li><a href="/link-3">Link 3</a></li>
            <li>Item without link</li>
            <li>Item without link <span>but has context (oddly)</span></li></ol>
          HTML
          .strip

          expect(chunk.html_content).to eq(expected_html_content)
        end
      end

      context "and the list style is 'choice'" do
        let(:step_with_bulleted_list) do
          {
            "title" => "This step has a bulleted list",
            "contents" => [
              {
                "text" => "Bulleted lists are also allowed.", "type" => "paragraph"
              },
              {
                "type" => "list",
                "style" => "choice",
                "contents" => [
                  { "href" => "/link-4", "text" => "Link 4", "context" => "rendered in span" },
                  { "href" => "/link-5", "text" => "Link 5" },
                  { "href" => "/link-6", "text" => "Link 6" },
                  { "text" => "Item without link" },
                  { "text" => "Item without link", "context" => "but has context (oddly)" },
                ],
              },
            ],
          }
        end
        let(:steps) { [step_with_bulleted_list] }

        it "constucts an unordered list based on the links contained when the lists style is 'choice'" do
          chunk = described_class.call(content_item).first

          expected_html_content = <<~HTML
            <p>Should be the first bit of content.</p>
            <h2>This step has a bulleted list</h2>
            <p>Bulleted lists are also allowed.</p>
            <ul><li><a href="/link-4">Link 4</a> <span>rendered in span</span></li>
            <li><a href="/link-5">Link 5</a></li>
            <li><a href="/link-6">Link 6</a></li>
            <li>Item without link</li>
            <li>Item without link <span>but has context (oddly)</span></li></ul>
          HTML
          .strip

          expect(chunk.html_content).to eq(expected_html_content)
        end
      end
    end

    context "when the step has 'and' logic" do
      let(:and_step) do
        {
          "logic" => "and",
          "title" => "This step contains and logic",
          "contents" => [
            {
              "text" => "And you should do this other thing too.", "type" => "paragraph"
            },
          ],
        }
      end
      let(:steps) { [numbered_step, and_step] }

      it "renders the steps with an 'and' paragraph at the start of the 'and' step" do
        chunk = described_class.call(content_item).first

        expected_html_content = <<~HTML
          <p>Should be the first bit of content.</p>
          <h2>A numbered step</h2>
          <p>This is a step with only a para.</p>

          <p>and</p>

          <h2>This step contains and logic</h2>
          <p>And you should do this other thing too.</p>
        HTML
        .strip

        expect(chunk.html_content).to eq(expected_html_content)
      end
    end

    context "when the step has 'or' logic" do
      let(:or_step) do
        {
          "logic" => "or",
          "title" => "This step contains or logic",
          "contents" => [
            {
              "text" => "Or you can do this other thing.", "type" => "paragraph"
            },
          ],
        }
      end
      let(:steps) { [numbered_step, or_step] }

      it "renders the steps with an 'or' paragraph at the start of the 'or' step" do
        chunk = described_class.call(content_item).first

        expected_html_content = <<~HTML
          <p>Should be the first bit of content.</p>
          <h2>A numbered step</h2>
          <p>This is a step with only a para.</p>

          <p>or</p>

          <h2>This step contains or logic</h2>
          <p>Or you can do this other thing.</p>
        HTML
        .strip

        expect(chunk.html_content).to eq(expected_html_content)
      end
    end

    context "when the step has unsanitized HTML" do
      let(:details) do
        {
          "step_by_step_nav" => {
            "steps" => [unsanitized_step],
            "title" => "Step by step nav title",
            "introduction" => [
              {
                "content" => "Sneaking a script<script>xss attack</script> in the introduction.",
                "content_type" => "text/govspeak",
              },
              {
                "content" => "<p>Sneaking a script<script>xss attack</script> in the introduction.</p>\n",
                "content_type" => "text/html",
              },
            ],
          },
        }
      end
      let(:unsanitized_step) do
        {
          "title" => "Maybe I will try and sneak <script>unsanitized HTML in here </script>",
          "contents" => [
            {
              "text" => "Sneaky script in a paragraph <script>xss attempt</script>", "type" => "paragraph"
            },
            {
              "type" => "list",
              "contents" => [
                { "href" => "/sneaky", "text" => "<script>sneaky script</script>" },
                { "href" => "/extra-sneaky", "text" => "nothing to see here", "context" => "<script>extra sneaky script</script>" },
              ],
            },
          ],
        }
      end

      it "sanitises the HTML" do
        chunk = described_class.call(content_item).first

        expected_html_content = <<~HTML
          <p>Sneaking a script in the introduction.</p>
          <h2>Maybe I will try and sneak &lt;script&gt;unsanitized HTML in here &lt;/script&gt;</h2>
          <p>Sneaky script in a paragraph &lt;script&gt;xss attempt&lt;/script&gt;</p>
          <ol><li><a href="/sneaky">&lt;script&gt;sneaky script&lt;/script&gt;</a></li>
          <li><a href="/extra-sneaky">nothing to see here</a> <span>&lt;script&gt;extra sneaky script&lt;/script&gt;</span></li></ol>
        HTML
        .strip

        expect(chunk.html_content).to eq(expected_html_content)
      end
    end
  end
end
