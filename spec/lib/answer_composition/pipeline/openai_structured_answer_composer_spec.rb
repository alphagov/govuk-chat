RSpec.describe AnswerComposition::Pipeline::OpenAIStructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
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
    let(:structured_response) do
      {
        answer: "VAT (Value Added Tax) is a [tax](link_2) applied to most goods and services in the UK.",
        answered: true,
        sources_used: %w[link_1],
      }.to_json
    end

    before do
      context.search_results = [search_result]
    end

    it "sends OpenAI a series of messages combining system prompt and the user question" do
      system_prompt_context = "[{:page_url=>\"link_1\", " \
                              ":page_title=>\"Title\", " \
                              ":page_description=>\"Description\", " \
                              ":context_headings=>[\"Heading 1\", \"Heading 2\"], " \
                              ":context_content=>\"<p>Some content</p><a href=\\\"link_2\\\">What is a tax?</a>\"}]"
      expected_message_history = [
        { role: "system", content: system_prompt(system_prompt_context) },
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

      it "calls OpenAI chat endpoint and assigns the correct values to the context's answer" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expect(context.answer.message.squish).to eq(
          "VAT (Value Added Tax) is a [tax][1] applied to most goods and services in the UK. [1]: https://www.test.gov.uk/what-is-tax",
        )
        expect(context.answer.status).to eq("success")
        expect(context.answer.llm_responses["structured_answer"]).to match(
          hash_including_openai_response_with_tool_call("generate_answer_using_retrieved_contexts"),
        )
      end

      it "sets the 'used' boolean to false for unused sources" do
        context.search_results = [search_result, unused_search_result]
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expect(context.answer.sources.map(&:used)).to eq([true, false])
      end

      it "assigns metrics to the answer" do
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expect(context.answer.metrics["structured_answer"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
        })
      end

      context "and answered is 'false'" do
        let(:structured_response) do
          {
            answer: "Sorry i cannot answer that question.",
            answered: false,
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
        end

        it "assigns metrics to the answer" do
          allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
          stub_openai_chat_completion_structured_response(
            expected_message_history,
            structured_response,
          )

          expect { described_class.call(context) }.to throw_symbol(:abort)

          expect(context.answer.metrics["structured_answer"]).to eq({
            duration: 1.5,
            llm_prompt_tokens: 13,
            llm_completion_tokens: 7,
          })
        end
      end
    end

    context "when OpenAI passes JSON back that is invalid against the Output schema" do
      let(:structured_response) { { answer: "VAT (Value Added Tax) is a tax applied to most goods and services in the UK." }.to_json }
      let(:expected_message_history) do
        array_including({ "role" => "user", "content" => question.message })
      end

      it "aborts the pipeline" do
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_invalid_llm_response",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::Schema::ValidationError message: The property '#/' did not contain a required property of 'answered'",
          metrics: {
            "structured_answer" => {
              duration: 1.5,
              llm_prompt_tokens: 13,
              llm_completion_tokens: 7,
            },
          },
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
        allow(AnswerComposition).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        expect(context).to receive(:abort_pipeline!).with(
          status: "error_invalid_llm_response",
          message: Answer::CannedResponses::UNSUCCESSFUL_REQUEST_MESSAGE,
          error_message: "class: JSON::ParserError message: unexpected token at 'this will blow up'",
          metrics: {
            "structured_answer" => {
              duration: 1.5,
              llm_prompt_tokens: 13,
              llm_completion_tokens: 7,
            },
          },
        )

        described_class.call(context)
      end
    end

    def system_prompt(context)
      sprintf(llm_prompts[:system_prompt], context:)
    end

    def llm_prompts
      Rails.configuration.llm_prompts.openai_structured_answer
    end
  end
end
