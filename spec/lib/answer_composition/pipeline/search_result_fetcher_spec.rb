RSpec.describe AnswerComposition::Pipeline::SearchResultFetcher, :chunked_content_index do
  let(:context) { build(:answer_pipeline_context) }
  let(:search_result) { build(:chunked_content_search_result) }
  let(:search_results) do
    Search::ResultsForQuestion::ResultSet.new(
      results: [search_result],
      rejected_results: [],
      metrics: { embedding_duration: 1.5, search_duration: 2.0, reranking_duration: 1.0 },
    )
  end

  before do
    allow(Search::ResultsForQuestion).to receive(:call).and_return(search_results)
  end

  context "when search results are returned" do
    it "updates the contexts search_results to the returned results" do
      described_class.call(context)
      expect(context.search_results).to eq(search_results.results)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      described_class.call(context)

      expect(context.answer.metrics["search_results"]).to match({
        duration: 1.5,
        embedding_duration: 1.5,
        search_duration: 2.0,
        reranking_duration: 1.0,
      })
    end
  end

  context "when no search results are found" do
    let(:context) { build(:answer_pipeline_context) }
    let(:search_results) do
      Search::ResultsForQuestion::ResultSet.new(
        results: [],
        rejected_results: [],
        metrics: { embedding_duration: 1.5, search_duration: 2, reranking_duration: 0.0 },
      )
    end

    it "aborts the pipeline and updates the answer's status and message attributes" do
      expect { described_class.call(context) }.to throw_symbol(:abort)
        .and change { context.answer.status }.to("unanswerable_no_govuk_content")
        .and change { context.answer.message }.to(Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      expect { described_class.call(context) }.to throw_symbol(:abort)

      expect(context.answer.metrics["search_results"]).to match({
        duration: 1.5,
        embedding_duration: 1.5,
        search_duration: 2.0,
        reranking_duration: 0.0,
      })
    end
  end
end
