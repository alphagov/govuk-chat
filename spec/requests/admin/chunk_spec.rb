RSpec.describe "Admin::ChunkController", :chunked_content_index do
  let(:content_chunk) { build :chunked_content_record }
  let(:chunk_id) { "chunk_id" }

  before do
    populate_chunked_content_index({ chunk_id => content_chunk })
  end

  describe "GET :show" do
    it "shows details for the chunk" do
      get admin_chunk_path(id: chunk_id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to have_displayed_chunk(content_chunk[:title])
    end

    it "returns a 404 when requesting non-existent chunk" do
      get admin_chunk_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    context "when back_link is provided in query params" do
      let(:back_link) { admin_search_path(params: { search_text: "pay my tax" }) }

      it "renders a back_link" do
        get admin_chunk_path(id: chunk_id, params: { back_link: })
        expect(response.body).to render_back_link(back_link)
      end
    end

    context "when back_link is not prefixed with /admin/search" do
      let(:back_link) { "/some/other/path" }

      it "hides the back link" do
        get admin_chunk_path(id: chunk_id, params: { back_link: })
        expect(response.body).not_to have_selector(".govuk-back-link")
      end
    end

    context "when back_link is not provided in query params" do
      it "hides the back link" do
        get admin_chunk_path(id: chunk_id)
        expect(response.body).not_to have_selector(".govuk-back-link")
      end
    end

  private

    def have_displayed_chunk(title)
      have_selector(".govuk-summary-list", text: Regexp.new(title))
    end

    def render_back_link(back_link)
      have_selector("a.govuk-back-link[href='#{back_link}']", text: "Back to results")
    end
  end
end
