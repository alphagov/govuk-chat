RSpec.describe AnswerComposition::Pipeline::OpenAIUnstructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:rephrased_question) { "Question rephrased by OpenAI" }
    let(:question) { create :question }
    let(:expected_message_history) do
      array_including({ "role" => "user", "content" => rephrased_question })
    end
    let(:search_result) { build(:chunked_content_search_result, _id: "1", score: 1.0) }
    let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [search_result], rejected_results: []) }
    let(:guardrails_response) do
      OutputGuardrails::FewShot::Result.new(
        triggered: false,
        guardrails: [],
        llm_response: "False | None",
      )
    end

    before do
      allow(Search::ResultsForQuestion).to receive(:call).and_return(results_for_question)
      allow(OutputGuardrails::FewShot).to receive(:call).and_return(guardrails_response)
    end

    it "sends OpenAI a series of messages combining system prompt, few shot messages and the user question" do
      few_shots = llm_prompts.answer_composition.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end

      expected_message_history = [
        { role: "system", content: system_prompt("Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>") },
        few_shots,
        { role: "user", content: question.message },
      ]
      .flatten

      request = stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

      described_class.call(question)

      expect(request).to have_been_made
    end

    context "when the question has been rephrased" do
      let(:conversation) { create(:conversation) }
      let(:second_question) { create(:question, conversation:) }

      before do
        create(:question, conversation:)
        stub_openai_chat_completion(
          array_including({ "role" => "user", "content" => second_question.message }),
          rephrased_question,
        )
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")
      end

      it "calls OpenAI chat endpoint and returns unsaved answer" do
        answer = described_class.call(second_question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question: second_question,
            message: "OpenAI responded with...",
            rephrased_question:,
            status: "success",
          },
        )
      end

      it "builds a source using attributes from the result" do
        answer = described_class.call(second_question)

        source = answer.sources.first

        expect(source).to have_attributes(
          exact_path: search_result.url,
          base_path: search_result.base_path,
          content_chunk_id: search_result._id,
          content_chunk_digest: search_result.digest,
          heading: search_result.heading_hierarchy.last,
          title: search_result.title,
        )
      end

      context "with multiple chunks from the same document" do
        let(:system_prompt_context) do
          "Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>\n\n" \
          "Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>"
        end
        let(:expected_message_history) do
          array_including(
            { "role" => "system", "content" => system_prompt(system_prompt_context) },
          )
        end

        let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [search_result, search_result], rejected_results: []) }

        it "builds one source for each result" do
          answer = described_class.call(question)
          expect(answer.sources.length).to eq(2)
        end

        it "builds a source using attributes from the result" do
          answer = described_class.call(question)

          source = answer.sources.first

          expect(source).to have_attributes(
            exact_path: search_result.url,
            base_path: search_result.base_path,
            title: search_result.title,
            heading: search_result.heading_hierarchy.last,
          )
        end
      end
    end

    context "when rephrasing produces the same question" do
      let(:conversation) { create(:conversation) }
      let!(:first_question) { create(:question, conversation:) }
      let(:second_question) { create(:question, conversation:) }
      let(:expected_message_history) do
        array_including(
          { "role" => "system", "content" => system_prompt("Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>") },
          { "role" => "user", "content" => second_question.message },
        )
      end
      let(:rephrased_question_prompt) do
        array_including(
          { "role" => "user", "content" => first_question.message },
          { "role" => "user", "content" => second_question.message },
        )
      end

      it "calls OpenAI chat endpoint and returns unsaved answer with rephrased_question: nil" do
        stub_openai_chat_completion(rephrased_question_prompt, second_question.message)
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(second_question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question: second_question,
            message: "OpenAI responded with...",
            rephrased_question: nil,
            status: "success",
          },
        )
      end
    end

    context "when the rephrased question contains a forbidden word" do
      let(:conversation) { create(:conversation) }
      let(:second_question) { create(:question, conversation:, message: user_input) }
      let(:rephrased_question) { "Question about forbidden_word rephrased by OpenAI" }
      let(:user_input) { "I want to know about forbidden_word" }

      before do
        create(:question, conversation:)
        stub_openai_chat_completion(
          array_including({ "role" => "user", "content" => second_question.message }),
          rephrased_question,
        )
      end

      it "returns an answer with a forbidden words message" do
        allow(Rails.configuration).to receive(:question_forbidden_words).and_return(%w[forbidden_word])

        answer = described_class.call(second_question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question: second_question,
            message: Answer::CannedResponses::FORBIDDEN_WORDS_RESPONSE,
            rephrased_question:,
            status: "abort_forbidden_words",
          },
        )
      end
    end

    context "when OpenSearch returns no results" do
      let(:question) { build_stubbed(:question, message: "I want to know about something that isn't on GOV.UK") }
      let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [], rejected_results: []) }

      it "returns an answer with a no content found message and an 'abort_no_govuk_content' status" do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE,
            rephrased_question: nil,
            status: "abort_no_govuk_content",
          },
        )
      end
    end

    context "when OpenAI raises a ContextLengthExceededError" do
      it "returns an unsaved answer with the error_context_length_exceeded status" do
        allow(GovukError).to receive(:notify)
        stub_openai_chat_completion_error(status: 400, code: "context_length_exceeded")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: Answer::CannedResponses::CONTEXT_LENGTH_EXCEEDED_RESPONSE,
            status: "error_context_length_exceeded",
            error_message: "class: OpenAIClient::ContextLengthExceededError message: Error message",
          },
        )
        expect(GovukError).to have_received(:notify).with(OpenAIClient::ContextLengthExceededError)
      end
    end

    context "when OpenAIClient raises a RequestError" do
      it "returns an unsaved answer with a generic unsuccessful request message which captures the error" do
        allow(GovukError).to receive(:notify)
        stub_openai_chat_completion_error

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: Answer::CannedResponses::OPENAI_CLIENT_ERROR_RESPONSE,
            status: "error_answer_service_error",
            error_message: "class: OpenAIClient::ClientError message: Error message",
          },
        )
        expect(GovukError).to have_received(:notify).with(OpenAIClient::RequestError)
      end
    end

  private

    def system_prompt(context)
      sprintf(llm_prompts.answer_composition.compose_answer.system_prompt, context:)
    end

    def expect_unsaved_answer_with_attributes(answer, attributes = {})
      expected_attributes = attributes.merge(persisted?: false)

      expect(answer).to be_a(Answer)
      expect(answer).to have_attributes(**expected_attributes)
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end
  end
end
