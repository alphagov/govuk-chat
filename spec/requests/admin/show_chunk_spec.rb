RSpec.describe "Admin::ChunkController", :chunked_content_index do
  let(:content_chunk) { build :chunked_content_record }
  let(:chunk_id) { "chunk_id" }

  before do
    populate_chunked_content_index({ chunk_id => content_chunk })
  end

  describe ":show" do
    it "shows details for the chunk" do
      get admin_chunk_path(id: chunk_id)
      expect(response).to have_http_status(:ok)
      assert_chunk_diplayed(
        description: content_chunk[:description],
        document_type: content_chunk[:document_type],
        base_path: content_chunk[:base_path],
        heading_hierarchy: content_chunk[:heading_hierarchy],
        content: content_chunk[:plain_content],
      )
    end

    it "raises Search::ChunkedContentRepository::NotFound when requesting non-existent chunk" do
      get admin_chunk_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

  private

    def assert_chunk_diplayed(heading_hierarchy:, description:, document_type:, base_path:, content:)
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(1)") do |row|
        expect(row).to have_selector("dt", text: "Heading hierarchy")
        expect(row).to have_selector("dd", text: heading_hierarchy.join(" | "))
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(2)") do |row|
        expect(row).to have_selector("dt", text: "Description")
        expect(row).to have_selector("dd", text: description)
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(3)") do |row|
        expect(row).to have_selector("dt", text: "Document type")
        expect(row).to have_selector("dd", text: document_type)
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(4)") do |row|
        expect(row).to have_selector("dt", text: "Base path")
        expect(row).to have_selector("dd", text: base_path)
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(5)") do |row|
        expect(row).to have_selector("dt", text: "Content")
        expect(row).to have_selector("dd", text: content)
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(6)") do |row|
        expect(row).to have_selector("dt", text: "Html content")
        expect(row).to have_selector("dd p", text: content)
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(7)") do |row|
        expect(row).to have_selector("dt", text: "On gov.uk")
        expect(row).to have_selector("dd a[href='https://www.gov.uk#{base_path}']", text: "https://www.gov.uk#{base_path}")
      end
      expect(response.body).to have_selector(".govuk-summary-list__row:nth-of-type(8)") do |row|
        expect(row).to have_selector("dt", text: "In content store")
        expect(row).to have_selector("dd a[href='https://www.gov.uk/api/content#{base_path}']", text: "https://www.gov.uk/api/content#{base_path}")
      end
    end
  end
end
