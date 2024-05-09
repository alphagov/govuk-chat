RSpec.describe "Admin::SearchController", :chunked_content_index do
  describe "GET :index" do
    context "with empty params" do
      before do
        get admin_search_path
      end

      it "renders an empty search box" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to render_search_box(value: "")
      end

      it "shows a message prompting to enter a search term" do
        expect(response.body).to include("No search performed")
          .and include("Please use the search box above to display results")
      end
    end

    context "with search_text in params" do
      let(:search_text) { "how do I pay tax" }
      let(:openai_embedding) { mock_openai_embedding(search_text) }
      let(:chunk_to_find) do
        build(:chunked_content_record,
              title: "Looking for this one",
              heading_hierarchy: ["Main header", "Sub header"],
              openai_embedding:)
      end

      before do
        stub_openai_embedding(search_text)
      end

      it "renders a search box populated with search text" do
        get admin_search_path, params: { search_text: }

        expect(response).to have_http_status(:ok)
        expect(response.body).to render_search_box(value: "how do I pay tax")
      end

      context "when there are chunks found" do
        before do
          populate_chunked_content_index([
            chunk_to_find,
            build(:chunked_content_record, title: "Shouldn't find this"),
          ])
        end

        it "renders a list of search results" do
          get admin_search_path, params: { search_text: }

          expect(response.body).to include_search_result(
            title: "Looking for this one",
            heading: "Sub header",
            text: chunk_to_find[:plain_content].truncate(100),
            score: 1.0,
          )
        end
      end
    end

  private

    def render_search_box(value:)
      have_selector("input[name='search_text'][value='#{value}']")
    end

    def include_search_result(title:, heading:, text:, score:)
      have_selector("td", text: title)
        .and have_selector("td", text: heading)
        .and have_selector("td", text:)
        .and have_selector("td", text: score)
    end
  end
end
