# frozen_string_literal: true

RSpec.describe ParallelSearchSpike::Run do
  describe ".call" do
    let(:io) { StringIO.new }

    around do |example|
      ClimateControl.modify(PARALLEL_SEARCH_MSEARCH_CONCURRENCY: nil) { example.run }
    end

    context "when strategy is msearch_only" do
      let(:phrases) { ["first phrase", "second phrase", "third phrase"] }
      let(:repository) { instance_double(Search::ChunkedContentRepository) }
      let(:raw_result) { build(:chunked_content_search_result, title: "raw title") }
      let(:weighted_high) { build(:weighted_search_result, title: "High score", weighted_score: 0.9) }
      let(:weighted_low) { build(:weighted_search_result, title: "Low score", weighted_score: 0.2) }
      let(:msearch_items) do
        [
          Search::ChunkedContentRepository::MsearchItem.new(results: [raw_result], error: nil, status: 200),
          Search::ChunkedContentRepository::MsearchItem.new(results: [], error: { "reason" => "sub-search boom" }, status: 500),
        ]
      end

      before do
        allow(Rails.configuration.search.thresholds).to receive_messages(
          minimum_score: 0.5,
          max_results: 2,
          retrieved_from_index: 5,
        )

        allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[0]).and_return([0.1, 0.2])
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[1]).and_raise(StandardError, "embedding boom")
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[2]).and_return([0.3, 0.4])
        allow(repository).to receive(:msearch_by_embeddings).and_return(msearch_items)
        allow(Search::ResultsForQuestion::Reranker).to receive(:call).and_return([weighted_high, weighted_low])
      end

      it "uses one msearch call and preserves phrase order while handling per-item errors" do
        runs = described_class.call(phrases:, strategies: [:msearch_only], top_n: 1, io:)

        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[0]).ordered
        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[1]).ordered
        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[2]).ordered

        expect(repository).to have_received(:msearch_by_embeddings).with(
          [[0.1, 0.2], [0.3, 0.4]],
          max_chunks: 5,
          max_concurrent_searches: nil,
        )
        expect(Search::ResultsForQuestion::Reranker).to have_received(:call).once

        phrase_results = runs.dig(0, :phrase_results)
        expect(phrase_results.map { |result| result[:phrase] }).to eq(phrases)

        expect(phrase_results[0]).to include(
          phrase: phrases[0],
          result_count: 1,
          top_titles: ["High score"],
          error: nil,
        )
        expect(phrase_results[0][:metrics]).to include(
          embedding_provider: "titan",
          search_strategy: "msearch_only",
        )
        expect(phrase_results[0][:metrics][:embedding_duration]).to be_a(Numeric)
        expect(phrase_results[0][:metrics][:search_duration]).to be_a(Numeric)
        expect(phrase_results[0][:metrics][:reranking_duration]).to be_a(Numeric)

        expect(phrase_results[1]).to include(
          phrase: phrases[1],
          result_count: 0,
          top_titles: [],
          error: { class: "StandardError", message: "embedding boom" },
        )
        expect(phrase_results[1][:metrics]).to include(embedding_provider: "titan")
        expect(phrase_results[1][:metrics][:embedding_duration]).to be_a(Numeric)

        expect(phrase_results[2]).to include(
          phrase: phrases[2],
          result_count: 0,
          top_titles: [],
          error: { class: "OpenSearch::MsearchItemError", message: "sub-search boom" },
        )
        expect(phrase_results[2][:metrics]).to include(
          embedding_provider: "titan",
          search_strategy: "msearch_only",
        )
        expect(phrase_results[2][:metrics][:embedding_duration]).to be_a(Numeric)
        expect(phrase_results[2][:metrics][:search_duration]).to be_a(Numeric)
      end
    end

    context "when strategy is hybrid" do
      let(:phrases) { ["first phrase", "second phrase", "third phrase"] }
      let(:repository) { instance_double(Search::ChunkedContentRepository) }
      let(:raw_result) { build(:chunked_content_search_result, title: "raw title") }
      let(:weighted_high) { build(:weighted_search_result, title: "High score", weighted_score: 0.9) }
      let(:weighted_low) { build(:weighted_search_result, title: "Low score", weighted_score: 0.2) }
      let(:msearch_items) do
        [
          Search::ChunkedContentRepository::MsearchItem.new(results: [raw_result], error: nil, status: 200),
          Search::ChunkedContentRepository::MsearchItem.new(results: [], error: { "reason" => "sub-search boom" }, status: 500),
        ]
      end

      before do
        allow(Rails.configuration.search.thresholds).to receive_messages(
          minimum_score: 0.5,
          max_results: 2,
          retrieved_from_index: 5,
        )

        allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[0]).and_return([0.1, 0.2])
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[1]).and_raise(StandardError, "embedding boom")
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[2]).and_return([0.3, 0.4])
        allow(repository).to receive(:msearch_by_embeddings).and_return(msearch_items)
        allow(Search::ResultsForQuestion::Reranker).to receive(:call).and_return([weighted_high, weighted_low])
      end

      it "parallelizes embeddings and uses a single msearch while preserving phrase order" do
        runs = described_class.call(phrases:, strategies: [:hybrid], top_n: 1, io:)

        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[0])
        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[1])
        expect(Search::TextToEmbedding).to have_received(:call).with(phrases[2])

        expect(repository).to have_received(:msearch_by_embeddings).with(
          [[0.1, 0.2], [0.3, 0.4]],
          max_chunks: 5,
          max_concurrent_searches: nil,
        )
        expect(Search::ResultsForQuestion::Reranker).to have_received(:call).once

        phrase_results = runs.dig(0, :phrase_results)
        expect(phrase_results.map { |result| result[:phrase] }).to eq(phrases)

        expect(phrase_results[0]).to include(
          phrase: phrases[0],
          result_count: 1,
          top_titles: ["High score"],
          error: nil,
        )
        expect(phrase_results[0][:metrics]).to include(
          embedding_provider: "titan",
          search_strategy: "hybrid",
        )
        expect(phrase_results[0][:metrics][:embedding_duration]).to be_a(Numeric)
        expect(phrase_results[0][:metrics][:search_duration]).to be_a(Numeric)
        expect(phrase_results[0][:metrics][:reranking_duration]).to be_a(Numeric)

        expect(phrase_results[1]).to include(
          phrase: phrases[1],
          result_count: 0,
          top_titles: [],
          error: { class: "StandardError", message: "embedding boom" },
        )
        expect(phrase_results[1][:metrics]).to include(embedding_provider: "titan")
        expect(phrase_results[1][:metrics][:embedding_duration]).to be_a(Numeric)

        expect(phrase_results[2]).to include(
          phrase: phrases[2],
          result_count: 0,
          top_titles: [],
          error: { class: "OpenSearch::MsearchItemError", message: "sub-search boom" },
        )
        expect(phrase_results[2][:metrics]).to include(
          embedding_provider: "titan",
          search_strategy: "hybrid",
        )
        expect(phrase_results[2][:metrics][:embedding_duration]).to be_a(Numeric)
        expect(phrase_results[2][:metrics][:search_duration]).to be_a(Numeric)
      end
    end

    context "when the msearch request fails" do
      let(:phrases) { ["first phrase", "second phrase"] }
      let(:repository) { instance_double(Search::ChunkedContentRepository) }

      before do
        allow(Rails.configuration.search.thresholds).to receive_messages(
          minimum_score: 0.5,
          max_results: 2,
          retrieved_from_index: 5,
        )
        allow(Search::TextToEmbedding).to receive(:call).and_return([0.1, 0.2])
        allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
        allow(repository).to receive(:msearch_by_embeddings).and_raise(StandardError, "opensearch timeout")
      end

      it "returns phrase errors for all phrases instead of raising" do
        runs = described_class.call(phrases:, strategies: [:msearch_only], io:)
        phrase_results = runs.dig(0, :phrase_results)

        expect(phrase_results.map { |result| result[:phrase] }).to eq(phrases)
        expect(phrase_results).to all include(
          result_count: 0,
          top_titles: [],
          metrics: {},
          error: { class: "StandardError", message: "opensearch timeout" },
        )
      end
    end

    context "when the hybrid msearch request fails" do
      let(:phrases) { ["first phrase", "second phrase"] }
      let(:repository) { instance_double(Search::ChunkedContentRepository) }

      before do
        allow(Rails.configuration.search.thresholds).to receive_messages(
          minimum_score: 0.5,
          max_results: 2,
          retrieved_from_index: 5,
        )
        allow(Search::TextToEmbedding).to receive(:call).and_return([0.1, 0.2])
        allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
        allow(repository).to receive(:msearch_by_embeddings).and_raise(StandardError, "opensearch timeout")
      end

      it "returns phrase errors for all phrases instead of raising" do
        runs = described_class.call(phrases:, strategies: [:hybrid], io:)
        phrase_results = runs.dig(0, :phrase_results)

        expect(phrase_results.map { |result| result[:phrase] }).to eq(phrases)
        expect(phrase_results).to all include(
          result_count: 0,
          top_titles: [],
          metrics: {},
          error: { class: "StandardError", message: "opensearch timeout" },
        )
      end
    end

    context "when PARALLEL_SEARCH_MSEARCH_CONCURRENCY is set" do
      let(:phrases) { ["first phrase"] }
      let(:repository) { instance_double(Search::ChunkedContentRepository) }
      let(:raw_result) { build(:chunked_content_search_result, title: "result title") }
      let(:weighted_result) { build(:weighted_search_result, title: "result title", weighted_score: 0.9) }
      let(:msearch_items) do
        [Search::ChunkedContentRepository::MsearchItem.new(results: [raw_result], error: nil, status: 200)]
      end

      around do |example|
        ClimateControl.modify(PARALLEL_SEARCH_MSEARCH_CONCURRENCY: "7") { example.run }
      end

      before do
        allow(Rails.configuration.search.thresholds).to receive_messages(
          minimum_score: 0.5,
          max_results: 2,
          retrieved_from_index: 5,
        )

        allow(Search::ChunkedContentRepository).to receive(:new).and_return(repository)
        allow(Search::TextToEmbedding).to receive(:call).with(phrases[0]).and_return([0.1, 0.2])
        allow(repository).to receive(:msearch_by_embeddings).and_return(msearch_items)
        allow(Search::ResultsForQuestion::Reranker).to receive(:call).and_return([weighted_result])
      end

      it "passes max_concurrent_searches through to the repository" do
        described_class.call(phrases:, strategies: [:msearch_only], io:)

        expect(repository).to have_received(:msearch_by_embeddings).with(
          [[0.1, 0.2]],
          max_chunks: 5,
          max_concurrent_searches: 7,
        )
      end
    end
  end
end
