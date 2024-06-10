RSpec.describe "Admin::SearchController", :chunked_content_index do
  describe "GET :index" do
    before do
      stub_const("Search::ResultsForQuestion::Reranker::DOCUMENT_TYPE_WEIGHTINGS", { "guide" => 1.2 })
    end

    context "with empty params" do
      before do
        get admin_search_path
      end

      it "renders an empty search box" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to render_search_box(value: "")
      end
    end

    context "with search_text in params" do
      let(:search_text) { "how do I pay tax" }
      let(:openai_embedding) { mock_openai_embedding(search_text) }
      let(:chunk_to_find) do
        build(:chunked_content_record,
              title: "Looking for this one",
              document_type: "guide",
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
        let(:chunk_id) { "the-chunk_id" }

        before do
          populate_chunked_content_index({
            chunk_id => chunk_to_find,
            "anything" => build(:chunked_content_record, title: "Shouldn't find this"),
          })
        end

        it "renders a list of search results" do
          get admin_search_path, params: { search_text: }

          expect(response.body).to include_search_result(
            title: "Looking for this one",
            id: chunk_id,
            heading: "Sub header",
            text: chunk_to_find[:plain_content].truncate(100),
            weighted_score: 1.2,
            score_calculation: "1.0 * 1.2 = 1.2",
            table: 1,
          )
        end

        it "renders results that don't meet the threshold" do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Search::ResultsForQuestion::WeightedResult).to receive(:score_calculation).and_return("1.0 * 0.5 = 1.0")
          # rubocop:enable RSpec/AnyInstance

          get admin_search_path, params: { search_text: }

          expect(response.body).to include_search_result(
            title: "Shouldn't find this",
            id: "anything",
            heading: "",
            text: "",
            weighted_score: /^\d\.\d*$/,
            score_calculation: "1.0 * 0.5 = 1.0",
            table: 2,
          )
        end
      end

      context "when there are no chunks found" do
        it "renders a message for no results found" do
          get admin_search_path, params: { search_text: }
          expect(response.body).to include("No results have been found for your query")
            .and include("Please rephrase and try again")
        end
      end
    end

  private

    def render_search_box(value:)
      have_selector("input[name='search_text'][value='#{value}']")
    end

    def include_search_result(title:, id:, heading:, text:, weighted_score:, score_calculation:, table:)
      back_link = admin_search_path(search_text:)
      href = admin_chunk_path(id:, params: { back_link:, score_calculation: })
      have_selector(".govuk-table:nth-of-type(#{table}) a[href='#{href}']", text: title)
        .and have_selector(".govuk-table:nth-of-type(#{table}) td", text: heading)
        .and have_selector(".govuk-table:nth-of-type(#{table}) td", text:)
        .and have_selector(".govuk-table:nth-of-type(#{table}) td", text: weighted_score)
    end
  end
end
