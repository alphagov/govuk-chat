RSpec.describe AnswerComposition::Pipeline::Claude::StructuredAnswerComposer, :aws_credentials_stubbed, :chunked_content_index do
  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:search_result) do
      build(
        :chunked_content_search_result,
        _id: "1",
        score: 1.0,
        exact_path: "/vat-rates#vat-basics",
        html_content: '<p>Some content</p><a href="/what-is-tax">What is a tax?</a>',
      )
    end
    let(:unused_search_result) do
      build(
        :chunked_content_search_result,
        _id: "2",
        score: 0.5,
        exact_path: "/vat-rates#vat-rates",
      )
    end

    before { context.search_results = [search_result] }

    it "uses Claude via Anthropic to assign the correct values to the context's answer" do
      answer = "VAT (Value Added Tax) is a tax applied to most goods and services in the UK."
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expect(context.answer.message.squish).to eq(answer)
      expect(context.answer.status).to eq("answered")
    end

    it "stores the LLM response" do
      answer = "answer"
      stub_claude_structured_answer(question.message, answer)

      described_class.call(context)

      expected_content = claude_messages_tool_use_block(
        input: { answer:, answered: true, sources_used: %w[link_1] },
        name: "output_schema",
      )
      expected_llm_response = claude_messages_response(
        content: [expected_content],
        usage: { cache_read_input_tokens: 20 },
        stop_reason: :tool_use,
      ).to_h
      expect(context.answer.llm_responses["structured_answer"]).to eq(expected_llm_response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
      stub_claude_structured_answer(question.message, "answer")

      described_class.call(context)

      expect(context.answer.metrics["structured_answer"]).to eq(
        duration: 1.5,
        llm_prompt_tokens: 30,
        llm_completion_tokens: 20,
        llm_cached_tokens: 20,
        model: BedrockModels::CLAUDE_SONNET,
      )
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        allow(Anthropic::BedrockClient).to receive(:new).and_call_original
        anthropic_request = stub_claude_structured_answer(question.message, "answer")

        described_class.call(context)

        expect(Anthropic::BedrockClient).to have_received(:new).with(hash_including(aws_region: "my-region"))
        expect(anthropic_request).to have_been_made
      end
    end

    it "sets the 'used' boolean to false for unused sources" do
      context.search_results = [search_result, unused_search_result]
      stub_claude_structured_answer(question.message, "answer")

      described_class.call(context)

      expect(context.answer.sources.map(&:used)).to eq([true, false])
    end

    context "when answered is false" do
      it "aborts the pipeline and sets the answer's status and message correctly" do
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          answered: false,
        )

        full_message = Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE +
          "\n\nYou might find these pages helpful:\n\n - [#{Plek.website_root}#{search_result.exact_path}](#{Plek.website_root}#{search_result.exact_path})"
        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.status }.to("unanswerable_llm_cannot_answer")
          .and change { context.answer.message }.to(full_message)
      end

      it "assigns metrics to the answer even when not answered" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_claude_structured_answer(
          question.message,
          "Sorry I cannot answer that question.",
          answered: false,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer.metrics["structured_answer"]).to eq(
          duration: 1.5,
          llm_prompt_tokens: 30,
          llm_completion_tokens: 20,
          llm_cached_tokens: 20,
          model: BedrockModels::CLAUDE_SONNET,
        )
      end
    end
  end
end
