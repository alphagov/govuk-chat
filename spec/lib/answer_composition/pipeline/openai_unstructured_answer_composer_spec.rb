RSpec.describe AnswerComposition::Pipeline::OpenAIUnstructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:question) { build(:question) }
    let(:expected_message_history) do
      array_including({ "role" => "user", "content" => question.message })
    end
    let(:search_result) do
      build(
        :chunked_content_search_result,
        _id: "1",
        score: 1.0,
        html_content: '<p>Some content</p><a href="/tax-returns">Tax returns</a>',
      )
    end
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:openai_response) { "VAT (Value Added Tax) is a [tax](link_1) applied to most goods and services in the UK." }

    before do
      context.search_results = [search_result]
      allow(AnswerComposition::Pipeline::Context).to receive(:new).and_return(context)
    end

    it "sends OpenAI a series of messages combining system prompt, few shot messages and the user question" do
      system_prompt = sprintf(
        llm_prompts[:system_prompt],
        context: "Title\nHeading 1\nHeading 2\nDescription\n" \
          "<p>Some content</p><a href=\"link_1\">Tax returns</a>",
      )
      few_shots = llm_prompts[:few_shots].flat_map do |few_shot|
        [
          { role: "user", content: few_shot[:user] },
          { role: "assistant", content: few_shot[:assistant] },
        ]
      end

      expected_message_history = [
        { role: "system", content: system_prompt },
        few_shots,
        { role: "user", content: question.message },
      ]
      .flatten

      request = stub_openai_chat_completion(expected_message_history, openai_response)

      described_class.call(context)

      expect(request).to have_been_made
    end

    it "calls OpenAI chat endpoint updates the message, status and llm response on the context's answer" do
      stub_openai_chat_completion(expected_message_history, openai_response)

      described_class.call(context)

      answer = context.answer
      expect(answer.message.squish).to eq(
        "VAT (Value Added Tax) is a [tax](/tax-returns) applied to most goods and services in the UK.",
      )
      expect(answer.status).to eq("success")
      expect(answer.llm_response).to eq(openai_response)
    end

    def llm_prompts
      Rails.configuration.llm_prompts.openai_unstructured_answer
    end
  end
end
