RSpec.describe AnswerComposition::Pipeline::OpenAIStructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:search_result) { build(:chunked_content_search_result, _id: "1", score: 1.0, exact_path: "/vat-rates#vat-basics") }
    let(:structured_response) do
      {
        answer: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK.",
        answered: true,
        call_for_action: "For more detailed information, you can visit [VAT Rates](https://www.gov.uk/vat-rates)",
        sources_used: ["/vat-rates#vat-basics"],
      }.to_json
    end

    before do
      context.search_results = [search_result]
    end

    it "sends OpenAI a series of messages combining system prompt, few shot messages and the user question" do
      few_shots = llm_prompts.openai_structured_answer.few_shots.flat_map do |few_shot|
        [
          { role: "user", content: few_shot.user },
          { role: "assistant", content: few_shot.assistant },
        ]
      end
      system_prompt_context = "[{:page_url=>\"/vat-rates#vat-basics\", " \
                              ":page_title=>\"Title\", " \
                              ":page_description=>\"Description\", " \
                              ":context_headings=>[\"Heading 1\", \"Heading 2\"], " \
                              ":context_content=>\"<p>Some content</p>\"}]"
      expected_message_history = [
        { role: "system", content: system_prompt(system_prompt_context) },
        few_shots,
        { role: "user", content: question.message },
      ]
      .flatten

      request = stub_openai_chat_completion_structured_response(
        expected_message_history,
        structured_response,
      )

      described_class.call(context)

      expect(request).to have_been_made
    end

    context "when a successful response is received" do
      let(:expected_message_history) do
        array_including({ "role" => "user", "content" => question.message })
      end
      let(:unused_search_result) { build(:chunked_content_search_result, _id: "2", score: 0.5, exact_path: "/vat-rates#vat-rates") }

      it "sets the 'used' boolean to false for unused sources" do
        context.search_results = [search_result, unused_search_result]
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expect(context.answer.sources.map(&:used)).to eq([true, false])
      end

      context "and a call to action is provided" do
        it "calls OpenAI chat endpoint and assigns the correct values to the context's answer" do
          stub_openai_chat_completion_structured_response(
            expected_message_history,
            structured_response,
          )

          described_class.call(context)

          expect(context.answer)
            .to have_attributes(
              message: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK.\n\nFor more detailed information, you can visit [VAT Rates](https://www.gov.uk/vat-rates)",
              status: "success",
              llm_response: structured_response,
            )
        end
      end

      context "and call for action is blank" do
        let(:structured_response) do
          {
            answer: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK.",
            answered: true,
            call_for_action: "",
            sources_used: ["/vat-rates#vat-basics"],
          }.to_json
        end

        it "calls OpenAI chat endpoint and assigns the correct values to the context's answer" do
          stub_openai_chat_completion_structured_response(
            expected_message_history,
            structured_response,
          )

          described_class.call(context)

          expect(context.answer)
            .to have_attributes(
              message: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK.",
              status: "success",
              llm_response: structured_response,
            )
        end
      end

      context "and answered is 'false'" do
        let(:structured_response) do
          {
            answer: "Sorry i cannot answer that question.",
            answered: false,
            call_for_action: "",
            sources_used: ["/vat-rates#vat-basics"],
          }.to_json
        end

        it "aborts the pipeline and sets the answers status to 'abort_llm_cannot_answer'" do
          stub_openai_chat_completion_structured_response(
            expected_message_history,
            structured_response,
          )

          expect { described_class.call(context) }.to throw_symbol(:abort)
            .and change { context.answer.status }.to("abort_llm_cannot_answer")
            .and change { context.answer.message }.to(Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE)
            .and change { context.answer.llm_response }.to(structured_response)
        end
      end
    end

    context "when OpenAI passes JSON back that is invalid against the Output schema" do
      let(:structured_response) { { answer: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK." }.to_json }
      let(:expected_message_history) do
        array_including({ "role" => "user", "content" => question.message })
      end

      it "aborts the pipeline" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_invalid_llm_response",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::Schema::ValidationError message: The property '#/' did not contain a required property of 'answered'",
          llm_response: structured_response,
        )

        described_class.call(context)
      end
    end

    context "when OpenAI passes invalid JSON in the response" do
      let(:structured_response) { "this will blow up" }
      let(:expected_message_history) do
        array_including({ "role" => "user", "content" => question.message })
      end

      it "aborts the pipeline" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_invalid_llm_response",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::ParserError message: unexpected token at 'this will blow up'",
          llm_response: structured_response,
        )

        described_class.call(context)
      end
    end

    def system_prompt(context)
      sprintf(llm_prompts.openai_structured_answer.system_prompt, context:)
    end

    def llm_prompts
      Rails.configuration.llm_prompts
    end
  end
end
