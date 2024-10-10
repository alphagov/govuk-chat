RSpec.describe Answer do
  describe "CannedResponses" do
    describe ".response_for_question_routing_label" do
      it "raises an error if the label doesn't exist in the config" do
        expect {
          described_class::CannedResponses.response_for_question_routing_label("not-here")
        }.to raise_error("No canned responses for not-here")
      end

      it "returns a random canned response" do
        responses = Rails.configuration.question_routing_labels["about_mps"][:canned_responses]

        response = described_class::CannedResponses.response_for_question_routing_label("about_mps")

        expect(responses).to include(response)
      end
    end
  end

  describe ".aggregate_status" do
    it "filters by the first portion of a status" do
      create_list(:answer, 2, status: :abort_answer_guardrails)
      create(:answer, status: :abort_question_routing)
      create_list(:answer, 3, status: :error_non_specific)
      create_list(:answer, 2, status: :error_timeout)

      expect(described_class.aggregate_status("abort").count).to eq(3)
      expect(described_class.aggregate_status("error").count).to eq(5)
    end
  end

  describe ".count_answers_guardrail_failures" do
    context "when only grouped by answer_guardrails_failures" do
      it "returns the count for each guardrail that failed" do
        create(:answer, answer_guardrails_failures: %w[guardrail_1 guardrail_2])
        create(:answer, answer_guardrails_failures: %w[guardrail_1])
        create(:answer, answer_guardrails_failures: %w[guardrail_1 guardrail_2 guardrail_3])
        create(:answer, answer_guardrails_failures: %w[guardrail_4])
        create(:answer, answer_guardrails_failures: [])

        counts = described_class.group(:answer_guardrails_failures)
                                .count_answer_guardrails_failures

        expect(counts).to eq({ "guardrail_1" => 3,
                               "guardrail_2" => 2,
                               "guardrail_3" => 1,
                               "guardrail_4" => 1 })
      end
    end

    context "when grouped by answer_guardrails_failures and other groupings" do
      it "returns the count for each guardrail that failed" do
        create(:answer,
               question_routing_label: "content_not_govuk",
               answer_guardrails_failures: %w[guardrail_1 guardrail_2],
               status: "success")
        create(:answer,
               question_routing_label: "content_not_govuk",
               answer_guardrails_failures: %w[guardrail_1],
               status: "success")
        create(:answer,
               question_routing_label: "content_not_govuk",
               answer_guardrails_failures: %w[guardrail_1],
               status: "abort_answer_guardrails")
        create(:answer,
               question_routing_label: "genuine_rag",
               answer_guardrails_failures: %w[guardrail_1 guardrail_2],
               status: "success")
        create(:answer,
               question_routing_label: "genuine_rag",
               answer_guardrails_failures: %w[guardrail_1],
               status: "success")
        create(:answer,
               question_routing_label: "genuine_rag",
               answer_guardrails_failures: [],
               status: "success")

        counts = described_class.group(:question_routing_label)
                                .group(:answer_guardrails_failures)
                                .group(:status)
                                .count_answer_guardrails_failures

        expect(counts).to eq({
          %w[content_not_govuk guardrail_1 success] => 2,
          %w[content_not_govuk guardrail_1 abort_answer_guardrails] => 1,
          %w[content_not_govuk guardrail_2 success] => 1,
          %w[genuine_rag guardrail_1 success] => 2,
          %w[genuine_rag guardrail_2 success] => 1,
        })
      end
    end

    context "when not grouped by answer_guardrails_failures" do
      it "raises an error" do
        expect { described_class.count_answer_guardrails_failures }
          .to raise_error("must have grouped by answer_guardrails_failures")
      end
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
      answer = build(:answer)

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

  describe "#assign_llm_response" do
    it "updates the given namespace with the hash" do
      answer = build(:answer)

      answer.assign_llm_response(
        "question_routing", { some: "hash" }
      )

      expect(answer.llm_responses).to eq(
        "question_routing" => {
          some: "hash",
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
