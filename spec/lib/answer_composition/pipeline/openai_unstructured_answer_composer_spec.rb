RSpec.describe AnswerComposition::Pipeline::OpenAIUnstructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:question) { build(:question) }
    let(:expected_message_history) do
      array_including({ "role" => "user", "content" => question.message })
    end
    let(:search_result) { build(:chunked_content_search_result, _id: "1", score: 1.0) }
    let(:context) { build(:answer_pipeline_context, question:) }

    before do
      context.search_results = [search_result]
      allow(AnswerComposition::Pipeline::Context).to receive(:new).and_return(context)
    end

    it "sends OpenAI a series of messages combining system prompt, few shot messages and the user question" do
      system_prompt = sprintf(
        llm_prompts.answer_composition.compose_answer.system_prompt,
        context: "Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>",
      )
      few_shots = llm_prompts.answer_composition.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end

      expected_message_history = [
        { role: "system", content: system_prompt },
        few_shots,
        { role: "user", content: question.message },
      ]
      .flatten

      request = stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

      described_class.call(context)

      expect(request).to have_been_made
    end

    it "calls OpenAI chat endpoint updates the message and status on the context's answer" do
      stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

      described_class.call(context)

      answer = context.answer
      expect(answer.message).to eq("OpenAI responded with...")
      expect(answer.status).to eq("success")
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end
  end
end
