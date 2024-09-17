RSpec.describe Answer do
  before do
    allow(Metrics).to receive(:increment_counter)
  end

  describe "after_commit" do
    it "increments answers_total counter" do
      answer = create(:answer, status: :abort_output_guardrails, question_routing_label: :genuine_rag, output_guardrail_status: :fail)

      expect(Metrics).to have_received(:increment_counter).with(
        "answers_total",
        status: answer.status,
        question_routing_label: answer.question_routing_label,
        output_guardrail_status: answer.output_guardrail_status,
      )
    end
  end

  describe "#sources" do
    it "implicitly orders sources by relevancy" do
      answer = create(:answer)
      source_1 = create(:answer_source, answer:, relevancy: 1, exact_path: "/1")
      source_2 = create(:answer_source, answer:, relevancy: 0, exact_path: "/2")

      expect(answer.reload.sources.strict_loading(false)).to eq([source_2, source_1])
    end
  end

  describe "#status" do
    it "contains the same values as the answer status config except for pending" do
      config_keys_minus_pending = Rails.configuration.answer_statuses.except("pending").keys.sort
      model_keys = described_class.statuses.keys.sort

      expect(model_keys).to eq(config_keys_minus_pending)
    end
  end

  describe "#build_sources_from_search_results" do
    it "sets sources on the answer" do
      search_result_a = build(:chunked_content_search_result, base_path: "/a")
      search_result_b = build(:chunked_content_search_result, base_path: "/b")
      answer = build(:answer)
      answer.build_sources_from_search_results([search_result_a, search_result_b])

      expect(answer.sources.length).to be(2)
      expect(answer.sources.first)
        .to have_attributes(
          relevancy: 0,
          base_path: search_result_a.base_path,
          exact_path: search_result_a.exact_path,
          title: search_result_a.title,
          content_chunk_id: search_result_a._id,
          content_chunk_digest: search_result_a.digest,
          heading: search_result_a.heading_hierarchy.last,
        )
      expect(answer.sources.second)
        .to have_attributes(
          relevancy: 1,
          base_path: search_result_b.base_path,
          exact_path: search_result_b.exact_path,
          title: search_result_b.title,
          content_chunk_id: search_result_b._id,
          content_chunk_digest: search_result_b.digest,
          heading: search_result_b.heading_hierarchy.last,
        )
    end

    it "resets any existing sources" do
      answer = build(:answer, :with_sources)
      search_result = build(:chunked_content_search_result)
      answer.build_sources_from_search_results([search_result])

      expect(answer.sources.length).to be(1)
      expect(answer.sources.first).to have_attributes(exact_path: search_result.exact_path)
    end
  end

  describe "#serialize_for_export" do
    it "returns a serialized answer with its sources" do
      answer = create(:answer, :with_sources)
      serialized_answer = answer.serialize_for_export

      expect(serialized_answer)
        .to include(answer.as_json)
        .and include("sources" => answer.sources.map(&:serialize_for_export))
    end
  end

  describe "#assign_metrics" do
    it "updates the given namespace with the values" do
      answer = create(:answer)

      answer.assign_metrics(
        "answer_composition", { duration: 1.1, llm_tokens: { prompt: 1, completion: 2 } }
      )

      expect(answer.metrics).to eq(
        "answer_composition" => {
          duration: 1.1,
          llm_tokens: { prompt: 1, completion: 2 },
        },
      )
    end
  end

  it "ensures the question routing labels and the enum values are in sync" do
    label_config = Rails.configuration.question_routing_labels
    enum_values = described_class.question_routing_labels.values

    expect(label_config.keys).to match_array(enum_values)
  end
end
