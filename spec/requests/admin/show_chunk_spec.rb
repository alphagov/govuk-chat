RSpec.describe "Admin::ChunkController", :chunked_content_index do
  let(:content_chunk) { build :chunked_content_record }
  let(:chunk_id) { "chunk_id" }

  before do
    populate_chunked_content_index({ chunk_id => content_chunk })
  end

  describe ":show" do
    it "shows details for the chunk" do
      get admin_chunks_path(id: chunk_id)
      expect(response).to have_http_status(:ok)
    end

    it "redirects to 404 when requesting non-existent chunk" do
      get admin_chunks_path(id: "does-not-exist")
      expect(response).to redirect_to("/404")
    end
  end
end
