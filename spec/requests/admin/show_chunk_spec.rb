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
      expect(response.body).to have_displayed_chunk
    end

    it "raises Search::ChunkedContentRepository::NotFound when requesting non-existent chunk" do
      get admin_chunk_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

  private

    def have_displayed_chunk
      have_selector(".govuk-summary-list", text: Regexp.new(content_chunk[:title]))
    end
  end
end
