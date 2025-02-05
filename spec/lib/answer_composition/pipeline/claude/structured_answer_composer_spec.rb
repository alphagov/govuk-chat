RSpec.describe AnswerComposition::Pipeline::Claude::StructuredAnswerComposer, :chunked_content_index do
  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }

    it "uses Bedrock converse endpoint to assign the correct values to the context's answer" do
      answer = "VAT (Value Added Tax) is a tax applied to most goods and services in the UK."

      stub_bedrock_converse(
        bedrock_claude_structured_answer_response(question.message, answer),
      )

      described_class.call(context)

      expect(context.answer.message).to eq(answer)
      expect(context.answer.status).to eq("answered")
    end

    it "stores the LLM response" do
      response = bedrock_claude_tool_response(
        { "answer" => "answer", "confidence" => 0.9 },
        tool_name: "answer_confidence",
      )

      stub_bedrock_converse(response)

      described_class.call(context)
      expect(context.answer.llm_responses["structured_answer"]).to match(response)
    end

    it "assigns metrics to the answer" do
      allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)

      stub_bedrock_converse(
        bedrock_claude_tool_response(
          { "answer" => "answer", "confidence" => 0.9 },
          tool_name: "answer_confidence",
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
  end
end
