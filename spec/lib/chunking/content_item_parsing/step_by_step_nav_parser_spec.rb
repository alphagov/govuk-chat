RSpec.describe Chunking::ContentItemParsing::StepByStepNavParser do
  include ContentItemParserExamples

  it_behaves_like "a chunking content item parser", described_class.allowed_schemas do
    let(:content_item) do
      build(
        :notification_content_item,
        schema_name: "step_by_step_nav",
        details:,
      )
    end
  end
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
  end
end
