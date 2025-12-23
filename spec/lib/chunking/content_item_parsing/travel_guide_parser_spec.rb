RSpec.describe Chunking::ContentItemParsing::TravelGuideParser do
  describe ".call" do
    let(:parts) do
      [
        {
          "title" => "Part 1",
          "slug" => "slug-1",
          "body" => [
            {
              "content_type" => "text/html",
              "content" => '<h2 id="heading-1">Heading 1</h2><p>Content 1</p><h2 id="heading-2">Heading 2</h2><p>Content 2</p>',
            },
            {
              "content_type" => "text/govspeak",
              "content" => "Content",
            },
          ],
        },
        {
          "title" => "Part 2",
          "slug" => "slug-2",
          "body" => [
            {
              "content_type" => "text/html",
              "content" => "<p>Content</p>",
            },
            {
              "content_type" => "text/govspeak",
              "content" => "Content",
            },
          ],
        },
      ]
    end
    let(:description) { "Travel advice for Thailand." }
    let(:country_name) { "Thailand" }
    let(:alert_status) { %w[avoid_all_but_essential_travel_to_whole_country avoid_all_travel_to_parts] }

    let(:content_item) do
      build(:notification_content_item,
            schema_name: "travel_advice",
            base_path: "/foreign-travel-advice/thailand",
            description:,
            details_merge: {
              "parts" => parts,
              "alert_status" => alert_status,
              "country" => { "name" => country_name, slug: "thailand" },
            })
    end

    it "adds the necessary chunks for travel alert statuses" do
      chunk_1, = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<ul>\n<li>FCDO advises against all but essential travel to Thailand.</li>\n<li>FCDO advises against all travel to parts of Thailand.</li>\n</ul>",
                                         heading_hierarchy: ["Alert status"],
                                         chunk_index: 0,
                                         exact_path: "/foreign-travel-advice/thailand")
    end

    context "when the country name contains HTML" do
      let(:country_name) { "<Thailand" }

      it "escapes the HTML in the chunk" do
        chunk, = described_class.call(content_item)

        expect(chunk.html_content).to include(
          "FCDO advises against all but essential travel to &lt;Thailand.",
        )
        expect(chunk.html_content).to include(
          "FCDO advises against all travel to parts of &lt;Thailand.",
        )
      end
    end

    describe "updating the content item description" do
      it "appends the travel advice to the content item description" do
        chunk_1, chunk_2, chunk_3 = described_class.call(content_item)
        description = "Travel advice for Thailand. FCDO advises against all but essential travel to Thailand. FCDO advises against all travel to parts of Thailand."

        expect(chunk_1.content_item["description"]).to eq(description)
        expect(chunk_2.content_item["description"]).to eq(description)
        expect(chunk_3.content_item["description"]).to eq(description)
      end

      it "does not modify the original content item description" do
        original_description = content_item["description"]
        chunk_1, = described_class.call(content_item)
        description = "Travel advice for Thailand. FCDO advises against all but essential travel to Thailand. FCDO advises against all travel to parts of Thailand."

        expect(chunk_1.content_item["description"]).to eq(description)
        expect(content_item["description"]).not_to eq(description)
        expect(content_item["description"]).to eq(original_description)
      end

      context "when there are no alert statuses" do
        let(:alert_status) { [] }

        it "does not modify the description if there are no alert statuses" do
          chunk_1, chunk_2, chunk_3 = described_class.call(content_item)
          description = "Travel advice for Thailand."

          expect(chunk_1.content_item["description"]).to eq(description)
          expect(chunk_2.content_item["description"]).to eq(description)
          expect(chunk_3.content_item["description"]).to eq(description)
        end
      end

      context "when the description is nil" do
        let(:description) { nil }

        it "handles a nil description gracefully" do
          chunk_1, chunk_2, chunk_3 = described_class.call(content_item)

          description = "FCDO advises against all but essential travel to Thailand. FCDO advises against all travel to parts of Thailand."

          expect(chunk_1.content_item["description"]).to eq(description)
          expect(chunk_2.content_item["description"]).to eq(description)
          expect(chunk_3.content_item["description"]).to eq(description)
        end
      end
    end

    it "converts the array of parts into an array of chunks" do
      _, chunk_1, chunk_2, chunk_3 = described_class.call(content_item)

      expect(chunk_1).to have_attributes(html_content: "<p>Content 1</p>",
                                         heading_hierarchy: ["Part 1", "Heading 1"],
                                         chunk_index: 1,
                                         exact_path: "/foreign-travel-advice/thailand#heading-1")

      expect(chunk_2).to have_attributes(html_content: "<p>Content 2</p>",
                                         heading_hierarchy: ["Part 1", "Heading 2"],
                                         chunk_index: 2,
                                         exact_path: "/foreign-travel-advice/thailand#heading-2")

      expect(chunk_3).to have_attributes(html_content: "<p>Content</p>",
                                         heading_hierarchy: ["Part 2"],
                                         chunk_index: 3,
                                         exact_path: "/foreign-travel-advice/thailand/slug-2")
    end

    context "when the alert status is not in the mapping" do
      let(:alert_status) { %w[avoid_all_travel_to_parts unknown_status] }

      it "reports an error if the alert status is unknown" do
        expect(GovukError).to receive(:notify).with(
          "Unknown travel alert status: unknown_status",
          extra: {
            content_item_id: content_item["content_id"],
            base_path: "/foreign-travel-advice/thailand",
          },
        )

        chunks = described_class.call(content_item)

        expect(chunks.first).to have_attributes(
          html_content: "<ul><li>FCDO advises against all travel to parts of Thailand.</li></ul>",
        )
      end
    end
  end
end
