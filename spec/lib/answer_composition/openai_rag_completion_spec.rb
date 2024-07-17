RSpec.describe AnswerComposition::OpenAIRagCompletion, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:rephrased_question) { "Question rephrased by OpenAI" }
    let(:question) { create :question }
    let(:expected_message_history) do
      array_including({ "role" => "user", "content" => rephrased_question })
    end
    let(:opensearch_chunk) { build(:chunked_content_record).except(:openai_embedding).merge(_id: "1", score: 1.0) }
    let(:chunk_result) { Search::ChunkedContentRepository::Result.new(**opensearch_chunk) }
    let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [chunk_result], rejected_results: []) }

    before do
      allow(AnswerComposition::QuestionRephraser).to receive(:call).and_return(rephrased_question)
      allow(Search::ResultsForQuestion).to receive(:call).and_return(results_for_question)
    end

    it "sends OpenAI a series of messages combining system prompt, few shot messages and the user question" do
      few_shots = llm_prompts.compose_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end

      expected_message_history = [
        { role: "system", content: system_prompt("Title\nHeading 1\nHeading 2\nDescription\n<p>Some content</p>") },
        few_shots,
        { role: "user", content: rephrased_question },
      ]
      .flatten

      request = stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

      described_class.call(question)

      expect(request).to have_been_made
    end

    context "when the question has been rephrased" do
      before do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")
      end

      it "calls OpenAI chat endpoint and returns unsaved answer" do
        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: "OpenAI responded with...",
            rephrased_question:,
            status: "success",
          },
        )
      end

      it "builds a source using attributes from the result" do
        answer = described_class.call(question)

        source = answer.sources.first

        expect(source).to have_attributes(
          exact_path: chunk_result.url,
          base_path: chunk_result.base_path,
          content_chunk_id: chunk_result._id,
          content_chunk_digest: chunk_result.digest,
          heading: chunk_result.heading_hierarchy.last,
        )
      end

      it "builds a source using the last heading in the heading_hierarchy to constuct the title" do
        answer = described_class.call(question)

        title = "#{chunk_result.title}: #{chunk_result.heading_hierarchy.last}"
        expect(answer.sources.first.title).to eq(title)
      end

      context "when the result has no heading_hierarchy" do
        let(:opensearch_chunk) do
          build(:chunked_content_record, heading_hierarchy: []).except(:openai_embedding).merge(_id: "1", score: 1.0)
        end

        it "builds a source using the title" do
          answer = described_class.call(question)
          expect(answer.sources.first.title).to eq(chunk_result.title)
        end
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

        let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [chunk_result, chunk_result], rejected_results: []) }

        it "only builds one source for the result" do
          answer = described_class.call(question)
          expect(answer.sources.length).to eq(1)
        end

        it "builds a source using attributes from the result" do
          answer = described_class.call(question)

          source = answer.sources.first

          expect(source).to have_attributes(
            exact_path: chunk_result.url,
            base_path: chunk_result.base_path,
            title: chunk_result.title,
            heading: chunk_result.heading_hierarchy.last,
          )
        end
      end
    end

    context "when rephrasing produces the same question" do
      let(:expected_message_history) do
        array_including({ "role" => "user", "content" => question.message })
      end

      before do
        allow(AnswerComposition::QuestionRephraser).to receive(:call).and_return(question.message)
      end

      it "calls OpenAI chat endpoint and returns unsaved answer with rephrased_question: nil" do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: "OpenAI responded with...",
            rephrased_question: nil,
            status: "success",
          },
        )
      end
    end

    context "when the rephrased question contains a forbidden word" do
      let(:question) { build_stubbed(:question, message: user_input) }
      let(:rephrased_question) { "Question about forbidden_word rephrased by OpenAI" }
      let(:user_input) { "I want to know about forbidden_word" }

      it "returns an answer with a forbidden words message" do
        allow(Rails.configuration).to receive(:question_forbidden_words).and_return(%w[forbidden_word])

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: Answer::CannedResponses::FORBIDDEN_WORDS_RESPONSE,
            rephrased_question:,
            status: "abort_forbidden_words",
          },
        )
      end
    end

    context "when OpenSearch returns no results" do
      let(:question) { build_stubbed(:question, message: "I want to know about something that isn't on GOV.UK") }
      let(:rephrased_question) { "Question where no content is found on GOV.UK" }

      let(:results_for_question) { Search::ResultsForQuestion::ResultSet.new(results: [], rejected_results: []) }

      it "returns an answer with a no content found message and an 'abort_no_govuk_content' status" do
        stub_openai_chat_completion(expected_message_history, "OpenAI responded with...")

        answer = described_class.call(question)

        expect_unsaved_answer_with_attributes(
          answer,
          {
            question:,
            message: Answer::CannedResponses::NO_CONTENT_FOUND_REPONSE,
            rephrased_question:,
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
      sprintf(llm_prompts.compose_answer.system_prompt, context:)
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
