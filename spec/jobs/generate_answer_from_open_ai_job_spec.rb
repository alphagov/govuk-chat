RSpec.describe GenerateAnswerFromOpenAiJob do
  describe "#perform" do
    let(:question) { create :question }
    let(:chat_history) { map_chat_history(question.conversation.questions) }

    it "calls OpenAI chat endpoint and saves result" do
      stub_openai_chat_completion(chat_history, "OpenAI responded with...")
      stub_search_api(%w[some context here])
      expect { described_class.new.perform(question.id) }.to change(Answer, :count).by(1)
      expect(question.answer.message).to eq("OpenAI responded with...")
    end

    context "with existing chat history" do
      let(:conversation) { create :conversation, :with_history }
      let(:question) { conversation.questions.last }

      it "calls openai with the chat history including the new question" do
        stub_openai_chat_completion(chat_history, "You can pay your self assessment...")
        stub_search_api(%w[some context here])
        expect { described_class.new.perform(question.id) }.to change(Answer, :count).by(1)
        expect(question.answer.message).to eq("You can pay your self assessment...")
        expect(map_chat_history(conversation.reload.questions)).to eq(
          [
            { content: "Hello", role: "user" },
            { content: "How can I help?", role: "assistant" },
            { content: "Pay my tax", role: "user" },
            { content: "Which type of tax?", role: "assistant" },
            { content: "self assessment", role: "user" },
            { content: "You can pay your self assessment...", role: "assistant" },
          ],
        )
      end
    end

  private

    def format_user_question(question)
      <<~OUTPUT
        #{AnswerGeneration::Prompts::GOVUK}

        Context:
        some
        context
        here

        Question:
        #{question}
      OUTPUT
    end

    def map_chat_history(questions)
      mapped_questions = questions.map(&method(:map_question)).flatten
      return mapped_questions if mapped_questions.last[:role] == "assistant"

      mapped_questions.last[:content] = format_user_question(mapped_questions.last[:content])
      mapped_questions
    end

    def map_question(question)
      return [{ role: "user", content: question.message }] if question.answer.nil?

      [
        { role: "user", content: question.message },
        { role: "assistant", content: question.answer.message },
      ]
    end

    # Temp - we will stub the real thing when we've built it
    def stub_search_api(result = [])
      allow(Retrieval::SearchApiV1Retriever).to receive(:call).and_return(result)
    end
  end
end
