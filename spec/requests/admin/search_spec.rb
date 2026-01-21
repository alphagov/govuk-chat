RSpec.describe "Admin::SearchController", :aws_credentials_stubbed, :chunked_content_index do
  describe "GET :index" do
    before do
      allow(Rails.configuration.search.thresholds).to receive_messages(minimum_score: 0.6, max_results: 5)
      allow(Rails.configuration.search).to receive(:document_types_by_schema).and_return(
        "guide" => { "document_types" => { "guide" => { "weight" => 1.2 } } },
        "answer" => { "document_types" => { "answer" => { "weight" => 0.5 } } },
      )
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
      let(:titan_embedding) { mock_titan_embedding(search_text) }
      # adjust the vector values to produce a vector that will be similar
      let(:close_embedding) { titan_embedding.map { |n| n * 1.05 } }
      let(:chunk_to_find) do
        build(:chunked_content_record,
              title: "Looking for this one",
              document_type: "guide",
              schema_name: "guide",
              heading_hierarchy: ["Main header", "Sub header"],
              titan_embedding:)
      end

      before do
        stub_bedrock_titan_embedding(search_text)
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
            "anything" => build(:chunked_content_record,
                                title: "Shouldn't find this",
                                document_type: "answer",
                                schema_name: "answer",
                                titan_embedding: close_embedding),
          })
        end

        it "renders a list of search results" do
          get admin_search_path, params: { search_text: }

          expect(response.body).to have_selector("#used-results") do |result|
            expect(result).to have_link("Looking for this one")
            expect(result).to have_selector("td", text: "Sub header")
            # matching a score that is ~1.2
            expect(result).to have_selector("td", text: /1.\d+/)
          end
        end

        it "includes score calculation and back links in links to results" do
          get admin_search_path, params: { search_text: }

          results = Search::ChunkedContentRepository.new.search_by_embedding(titan_embedding, max_chunks: 2)
          result = results.detect { |r| r.digest == chunk_to_find[:digest] }
          weighted_result = Search::ResultsForQuestion::Reranker.call(results).detect { |r| r.digest == chunk_to_find[:digest] }
          document_type_weight = weighted_result.weighting
          weighted_score = weighted_result.weighted_score

          expected_link = admin_chunk_path(id: chunk_id, back_link: admin_search_path(search_text:))
          score_calculation_pattern = /#{result.score}
                                      #{Regexp.escape(CGI.escape(' * '))}
                                      #{document_type_weight}
                                      #{Regexp.escape(CGI.escape(' = '))}
                                      #{weighted_score}/x
          link_pattern = /#{Regexp.escape(expected_link)}&score_calculation=#{score_calculation_pattern}/
          expect(response.body).to have_link("Looking for this one", href: link_pattern)
        end

        it "renders a description for the results table" do
          get admin_search_path, params: { search_text: }
          expected_text = "1 result (max 5) over the weighted score threshold of 0.6"
          expect(response.body).to have_selector("#used-results caption", text: expected_text)
        end

        it "renders results that don't meet the threshold" do
          get admin_search_path, params: { search_text: }
          expect(response.body).to have_selector("#near-miss-results") do |result|
            expect(result).to have_link("Shouldn't find this")
          end
        end

        it "renders a description for the rejected results table" do
          get admin_search_path, params: { search_text: }
          expected_text = "1 more result retrieved from the search index"
          expect(response.body).to have_selector("#near-miss-results caption", text: expected_text)
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
  end
end
