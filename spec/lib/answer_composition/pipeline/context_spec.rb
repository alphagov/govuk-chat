RSpec.describe AnswerComposition::Pipeline::Context do
  describe "#initialize" do
    it "builds an answer object from the question" do
      question = build(:question)
      instance = described_class.new(question)

      expect(instance.answer)
        .to be_a(Answer)
        .and have_attributes(question:)
    end

    it "sets the question_message based on the question" do
      question = build(:question, message: "What is the current VAT rate?")
      instance = described_class.new(question)
      expect(instance.question_message).to eq("What is the current VAT rate?")
    end

    it "sets an initial aborted status of false" do
      instance = described_class.new(build(:question))
      expect(instance).not_to be_aborted
    end
  end

  describe "#abort_pipeline" do
    it "changes the aborted status" do
      instance = described_class.new(build(:question))
      instance.abort_pipeline
      expect(instance).to be_aborted
    end

    it "returns the answer" do
      instance = described_class.new(build(:question))
      expect(instance.abort_pipeline).to be(instance.answer)
    end

    it "accepts arguments to update the answer model" do
      instance = described_class.new(build(:question))
      args = { message: "answer", status: "answered" }
      instance.abort_pipeline(**args)
      expect(instance.answer).to have_attributes(args)
    end

    it "sets all sources to unused" do
      instance = described_class.new(build(:question))
      instance.search_results = build_list(:weighted_search_result, 2)

      instance.abort_pipeline

      expect(instance.answer.sources.map(&:used)).to all(be false)
    end

    it "assigns metrics" do
      instance = described_class.new(build(:question))
      args = { message: "answer", metrics: { "namespace" => { value: 1 } } }
      instance.abort_pipeline(**args)
      expect(instance.answer.metrics).to eq("namespace" => { value: 1 })
    end

    it "assigns an llm_response" do
      instance = described_class.new(build(:question))
      args = { message: "answer", llm_response: { "output_guardrails" => { some: "data" } } }
      instance.abort_pipeline(**args)
      expect(instance.answer.llm_responses["output_guardrails"]).to eq({ some: "data" })
    end
  end

  describe "#abort_pipeline!" do
    it "throws an abort symbol" do
      instance = described_class.new(build(:question))
      expect { instance.abort_pipeline! }.to throw_symbol(:abort)
    end

    it "delegates to #abort_pipeline" do
      instance = described_class.new(build(:question))
      args = { message: "answer", status: "answered" }
      allow(instance).to receive(:abort_pipeline)
      expect { instance.abort_pipeline!(**args) }.to throw_symbol(:abort)
      expect(instance).to have_received(:abort_pipeline).with(args)
    end
  end

  describe "#question_message=" do
    it "updates the question_message attribute" do
      instance = described_class.new(build(:question))
      instance.question_message = "Next question?"

      expect(instance.question_message).to eq("Next question?")
    end

    context "when the question_message is same as the question message" do
      it "resets answer.rephrased_question" do
        instance = described_class.new(build(:question, message: "First question"))

        instance.question_message = "First question"
        expect(instance.answer.rephrased_question).to be_nil
      end
    end

    context "when the question_message is different to the question's message" do
      it "updates answer.rephrased_question to question_message" do
        instance = described_class.new(build(:question, message: "First question"))

        instance.question_message = "Rephrased question"
        expect(instance.answer.rephrased_question).to eq("Rephrased question")
      end
    end
  end

  describe "#search_results=" do
    let(:search_results) { build_list(:weighted_search_result, 2) }

    it "updates the search_results attribute" do
      instance = described_class.new(build(:question))
      instance.search_results = search_results

      expect(instance.search_results).to eq(search_results)
    end

    it "builds sources on the answer by delegating to answers method" do
      instance = described_class.new(build(:question))

      expect { instance.search_results = search_results }
        .to change { instance.answer.sources.length }.from(0)
    end
  end

  describe "#update_sources_from_exact_urls_used" do
    let(:instance) { described_class.new(build(:question)) }
    let(:answer) { instance.answer }

    it "sets used to 'true' for used sources" do
      source = build(:answer_source,
                     used: false,
                     chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat"))

      answer.sources = [source]

      instance.update_sources_from_exact_urls_used([source.chunk.govuk_url])

      expect(answer.sources).to contain_exactly(source)
      expect(source.used).to be(true)
    end

    it "sets used to 'false' for unused sources" do
      used_source = build(:answer_source,
                          chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat"))

      unused_source = build(:answer_source,
                            used: true,
                            chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat-basics"))

      answer.sources = [used_source, unused_source]

      instance.update_sources_from_exact_urls_used([used_source.chunk.govuk_url])

      expect(answer.sources).to contain_exactly(used_source, unused_source)
      expect(unused_source.used).to be(false)
    end

    it "handles invalid exact_paths gracefully" do
      source = build(:answer_source,
                     used: false,
                     chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat"))

      answer.sources = [source]

      instance.update_sources_from_exact_urls_used(["/made-up-path"])

      expect(answer.sources).to contain_exactly(source)
      expect(source.used).to be(false)
    end

    it "orders the relevancy of sources based on the order of the exact_paths passed in" do
      first_used_source = build(:answer_source,
                                relevancy: 1,
                                chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat"))

      second_used_source = build(:answer_source,
                                 relevancy: 0,
                                 chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat-basics"))

      answer.sources = [second_used_source, first_used_source]

      instance.update_sources_from_exact_urls_used(
        [
          first_used_source.govuk_url,
          second_used_source.govuk_url,
        ],
      )

      expect(answer.sources).to contain_exactly(first_used_source, second_used_source)
      expect(first_used_source.relevancy).to eq(0)
      expect(second_used_source.relevancy).to eq(1)
    end

    it "orders used sources before unused sources" do
      unused_source = build(:answer_source,
                            relevancy: 0,
                            chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat"))

      used_source = build(:answer_source,
                          relevancy: 1,
                          chunk: build(:answer_source_chunk, exact_path: "/vat-rates#vat-basics"))

      answer.sources = [unused_source, used_source]

      instance.update_sources_from_exact_urls_used([used_source.govuk_url])

      expect(answer.sources).to contain_exactly(used_source, unused_source)
      expect(used_source.relevancy).to eq(0)
      expect(unused_source.relevancy).to eq(1)
    end
  end

  describe "#search_results_prompt_formatted" do
    it "returns an array of hashes with the correct structure" do
      instance = described_class.new(build(:question))
      instance.search_results = build_list(:weighted_search_result, 2)
      link_token_mapper = AnswerComposition::LinkTokenMapper.new

      formatted = instance.search_results_prompt_formatted(link_token_mapper)

      formatted.each_with_index do |hash, index|
        result = instance.search_results[index]
        expect(hash).to include(
          page_url: link_token_mapper.map_link_to_token(result.exact_path),
          page_title: result.title,
          page_description: result.description,
          context_headings: result.heading_hierarchy,
          context_content: link_token_mapper.map_links_to_tokens(
            result.html_content,
            result.exact_path,
          ),
          llm_instructions: result.llm_instructions,
        )
      end
    end

    it "omits elements where the value is nil" do
      instance = described_class.new(build(:question))
      instance.search_results = [build(:weighted_search_result, llm_instructions: nil)]
      link_token_mapper = AnswerComposition::LinkTokenMapper.new

      formatted = instance.search_results_prompt_formatted(link_token_mapper)

      expect(formatted[0].key?(:llm_instructions)).to be false
    end
  end
end
