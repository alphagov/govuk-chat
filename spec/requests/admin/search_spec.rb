RSpec.describe "Admin::SearchController", :chunked_content_index do
  describe "GET :index" do
    context "with empty params" do
      it "renders an empty search box" do
        get admin_search_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to render_search_box(value: "")
      end
    end

    context "with search_text in params" do
      let(:search_text) { "how do I pay tax" }
      let(:openai_embedding) { mock_openai_embedding(search_text) }

      before do
        allow(Search::TextToEmbedding)
          .to receive(:call)
          .with(search_text)
          .and_return(openai_embedding)

        populate_chunked_content_index([
          build(:chunked_content_record, title: "Looking for this one", openai_embedding:),
          build(:chunked_content_record, title: "Shouldn't find this"),
        ])
      end

      it "renders a search box populated with search text" do
        get admin_search_path, params: { search_text: }

        expect(response).to have_http_status(:ok)
        expect(response.body).to render_search_box(value: "how do I pay tax")
      end

      it "renders a list of search results" do
        get admin_search_path, params: { search_text: }

        expect(response.body).to include_search_result(text: "Looking for this one", score: 1.0)
      end
    end

  private

    def render_search_box(value:)
      have_selector("input[name='search_text'][value='#{value}']")
    end

    def include_search_result(text:, score:)
      have_selector("td", text:).and have_selector("td", text: score)
    end
  end
end
