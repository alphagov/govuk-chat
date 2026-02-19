RSpec.describe AnswerComposition::Pipeline::Claude::StructuredAnswerComposer, :aws_credentials_stubbed, :chunked_content_index do
  describe ".call" do
    let(:question) { build :question }
    let(:answer) { "VAT (Value Added Tax) is a tax applied to most goods and services in the UK." }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:search_result) do
      build(
        :weighted_search_result,
        _id: "1",
        score: 1.0,
        exact_path: "/vat-rates#vat-basics",
        html_content: '<p>Some content</p><a href="/what-is-tax">What is a tax?</a>',
      )
    end
    let(:unused_search_result) do
      build(
        :weighted_search_result,
        _id: "2",
        score: 0.5,
        exact_path: "/vat-rates#vat-rates",
      )
    end

    before { context.search_results = [search_result] }

    shared_examples "llm cannot answer the question" do |options|
      it "aborts the pipeline and sets the answer's status and message correctly" do
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          **options,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.status }.to("unanswerable_llm_cannot_answer")
          .and change { context.answer.message }.to(Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE)
      end

      it "sets sources used to false for all sources" do
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          **options,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.sources.first.used }.to(false)
      end

      it "assigns metrics to the answer even when not answered" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          **options,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer.metrics["structured_answer"]).to eq(
          duration: 1.5,
          llm_prompt_tokens: 30,
          llm_completion_tokens: 20,
          llm_cached_tokens: 20,
          model: BedrockModels.model_id(:claude_sonnet_4_0),
        )
      end

      it "stores the LLM response even when not answered" do
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          **options,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expected_content = claude_messages_tool_use_block(
          input: {
            answer: "Sorry I cannot answer that question.",
            **options,
          },
          name: "output_schema",
        )
        expected_llm_response = {
          "response" => claude_messages_response(
            content: [expected_content],
            usage: { cache_read_input_tokens: 20 },
            stop_reason: :tool_use,
          ).to_h.stringify_keys,
          "link_token_mapping" => {
            "link_1" => "https://www.test.gov.uk/vat-rates#vat-basics",
            "link_2" => "https://www.test.gov.uk/what-is-tax",
          },
        }
        expect(context.answer.llm_responses["structured_answer"]).to eq(expected_llm_response)
      end
    end

    it_behaves_like "a claude answer composition component with a configurable model", "BEDROCK_CLAUDE_STRUCTURED_ANSWER_COMPOSER_MODEL" do
      let(:pipeline_step) { described_class.new(context) }
      let(:stubbed_request) do
        stub_claude_structured_answer(
          question.message,
          answer,
          chat_options: { bedrock_model: described_class.bedrock_model },
        )
      end
    end

    it "uses Claude via Anthropic to assign the correct values to the context's answer" do
      answer = "VAT (Value Added Tax) is a tax applied to most goods and services in the UK."
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expect(context.answer.message.squish).to eq(answer)
      expect(context.answer)
        .to have_attributes(status: "answered", completeness: "complete")
    end

    it "stores the LLM response" do
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expected_content = claude_messages_tool_use_block(
        input: { answer:, answered: true, sources_used: %w[link_1], answer_completeness: "complete" },
        name: "output_schema",
      )
      expected_llm_response = {
        "response" => claude_messages_response(
          content: [expected_content],
          usage: { cache_read_input_tokens: 20 },
          stop_reason: :tool_use,
        ).to_h.stringify_keys,
        "link_token_mapping" => {
          "link_1" => "https://www.test.gov.uk/vat-rates#vat-basics",
          "link_2" => "https://www.test.gov.uk/what-is-tax",
        },
      }
      expect(context.answer.llm_responses["structured_answer"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expect(context.answer.metrics["structured_answer"]).to eq(
        duration: 1.5,
        llm_prompt_tokens: 30,
        llm_completion_tokens: 20,
        llm_cached_tokens: 20,
        model: BedrockModels.model_id(:claude_sonnet_4_0),
      )
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original
        anthropic_request = stub_claude_structured_answer(question.message, answer)

        described_class.call(context)

        expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(anthropic_request).to have_been_made
      end
    end

    it "sets the 'used' boolean to false for unused sources" do
      context.search_results = [search_result, unused_search_result]
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expect(context.answer.sources.map(&:used)).to eq([true, false])
    end

    it "aborts the pipeline when only an unknown source is used" do
      structured_response = {
        answered: true,
        sources_used: %w[unknown_link_token],
        answer_completeness: "complete",
      }
      stub_claude_structured_answer(
        question.message, "Here is an answer.", **structured_response
      )

      expect { described_class.call(context) }.to throw_symbol(:abort)
        .and change { context.answer.sources.first.used }.to(false)
    end

    context "when answered is false" do
      include_examples "llm cannot answer the question", {
        answered: false,
        sources_used: [],
        answer_completeness: "incomplete",
      }
    end

    context "when sources_used is empty" do
      include_examples "llm cannot answer the question", {
        answered: true,
        sources_used: [],
        answer_completeness: "complete",
      }
    end
  end
end
