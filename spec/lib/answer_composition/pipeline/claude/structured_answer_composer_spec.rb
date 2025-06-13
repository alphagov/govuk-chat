RSpec.describe AnswerComposition::Pipeline::Claude::StructuredAnswerComposer, :chunked_content_index do
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

    before do
      context.search_results = [search_result]
    end

    it "uses Bedrock converse endpoint to assign the correct values to the context's answer" do
      answer = "VAT (Value Added Tax) is a tax applied to most goods and services in the UK."

      stub_bedrock_converse(
        bedrock_claude_structured_answer_response(question.message, answer),
      )

      described_class.call(context)

      expect(context.answer.message.squish).to eq(answer)
      expect(context.answer.status).to eq("answered")
    end

    it "stores the LLM response" do
      response = bedrock_claude_tool_response(
        { "answer" => "answer", "answered" => true, "sources_used" => %w[link_1] },
        tool_name: "output_schema",
      )

      stub_bedrock_converse(response)

      described_class.call(context)
      expect(context.answer.llm_responses["structured_answer"]).to match(response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      stub_bedrock_converse(
        bedrock_claude_tool_response(
          { "answer" => "answer", "answered" => true, "sources_used" => %w[link_1] },
          tool_name: "output_schema",
          input_tokens: 15,
          output_tokens: 25,
        ),
      )

      described_class.call(context)

      expect(context.answer.metrics["structured_answer"]).to eq({
        duration: 1.5,
        llm_prompt_tokens: 15,
        llm_completion_tokens: 25,
      })
    end

    it "uses an overridden AWS region if set" do
      ClimateControl.modify(CLAUDE_AWS_REGION: "my-region") do
        bedrock_client = Aws::BedrockRuntime::Client.new(stub_responses: true)

        allow(Aws::BedrockRuntime::Client).to(
          receive(:new).with(region: "my-region").and_return(bedrock_client),
        )

        bedrock_client.stub_responses(
          :converse,
          bedrock_claude_structured_answer_response(question.message, "answer"),
        )

        described_class.call(context)
        expect(bedrock_client.api_requests.size).to eq(1)
      end
    end

    it "sets the 'used' boolean to false for unused sources" do
      context.search_results = [search_result, unused_search_result]
      response = bedrock_claude_tool_response(
        { "answer" => "answer", "answered" => true, "sources_used" => %w[link_1] },
        tool_name: "output_schema",
      )

      stub_bedrock_converse(response)

      described_class.call(context)
      expect(context.answer.sources.map(&:used)).to eq([true, false])
    end

    context "when answered is 'false'" do
      it "aborts the pipeline and sets the answers status and message to the correct values" do
        stub_bedrock_converse(
          bedrock_claude_structured_answer_response(
            question.message,
            "Sorry i cannot answer that question.",
            answered: false,
          ),
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.status }.to("unanswerable_llm_cannot_answer")
          .and change { context.answer.message }.to(Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE)
      end

      it "assigns metrics to the answer" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

        stub_bedrock_converse(
          bedrock_claude_tool_response(
            { "answer" => "answer", "answered" => false, "sources_used" => [] },
            tool_name: "output_schema",
            input_tokens: 15,
            output_tokens: 25,
          ),
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
        expect(context.answer.metrics["structured_answer"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 15,
          llm_completion_tokens: 25,
        })
      end
    end
  end
end
