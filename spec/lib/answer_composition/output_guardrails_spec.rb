RSpec.describe AnswerComposition::OutputGuardrails do
  before do
    allow(Rails.logger).to receive(:error)
  end

  context "when the request is successful" do
    let(:input) { "This is a test input." }
    let(:expected_messages) do
      [
        { role: "system", content: system_prompt },
        {
          role: "user",
          content: <<~PROMPT,
            Here is the answer to check: #{input}. Remember
            to return True or False and the number associated with the
            guardrail requirement if it returns True. Remember
            to carefully consider your judgement with respect to the
            instructions provided.
          PROMPT
        },
      ]
    end

    it "calls openAI with the correct payload and returns the guardrail result" do
      guardrail_result = "True"
      stub_openai_chat_completion(expected_messages, guardrail_result, chat_options: {
        model: "gpt-4o",
        max_tokens: 25, # It takes 23 tokens for True | "1, 2, 3, 4, 5, 6, 7"
      })
      expect(described_class.call(input)).to eq(guardrail_result)
    end

    context "when there is an OpenAIClient::ClientError" do
      before do
        stub_openai_chat_completion_error
      end

      it "raises a OpenAIClient::RequestError with a modified message" do
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OpenAIClient::RequestError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "could not run guardrail: This is a test input.",
                                     cause: an_instance_of(OpenAIClient::ClientError))),
          )
      end

      it "Logs the error" do
        expect { described_class.call(input) }.to raise_error(OpenAIClient::RequestError)
        expect(Rails.logger).to have_received(:error).with("OpenAI error running guardrail: the server responded with status 400")
      end
    end

    context "when there is an OpenAIClient::ContextLengthExceededError" do
      before do
        stub_openai_chat_completion_error(code: "context_length_exceeded")
      end

      it "raises a OpenAIClient::ContextLengthExceededError with a modified message" do
        expect { described_class.call(input) }
          .to raise_error(
            an_instance_of(OpenAIClient::ContextLengthExceededError)
              .and(having_attributes(response: an_instance_of(Hash),
                                     message: "Exceeded context length running guardrail: This is a test input.",
                                     cause: an_instance_of(OpenAIClient::ContextLengthExceededError))),
          )
      end

      it "Logs the error" do
        expect { described_class.call(input) }.to raise_error(OpenAIClient::ContextLengthExceededError)
        expect(Rails.logger).to have_received(:error).with("Exceeded context length running guardrail: the server responded with status 400")
      end
    end
  end

  def system_prompt
    Rails.configuration.llm_prompts.guardrails.few_shot.system_prompt
      .gsub("{date}", Time.zone.today.strftime("%A %d %B %Y"))
  end
end
