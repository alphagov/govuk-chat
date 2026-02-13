RSpec.describe AnswerComposition::Pipeline::OpenAI::StructuredAnswerComposer, :chunked_content_index do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".call" do
    let(:question) { build :question }
    let(:context) { build(:answer_pipeline_context, question:) }
    let(:search_result) do
      build(
        :weighted_search_result,
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

    before { context.search_results = [search_result] }

    shared_examples "llm cannot answer the question" do |structured_response_json|
      it "aborts the pipeline and sets the answers status" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response_json,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.status }.to("unanswerable_llm_cannot_answer")
          .and change { context.answer.message }.to(Answer::CannedResponses::LLM_CANNOT_ANSWER_MESSAGE)
      end

      it "sets sources used to false for all sources" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response_json,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.sources.first.used }.to(false)
      end

      it "assigns metrics to the answer" do
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response_json,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)

        expect(context.answer.metrics["structured_answer"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
          llm_cached_tokens: 10,
          model: "gpt-4o-mini-2024-07-18",
        })
      end
    end

    it "sends OpenAI a series of messages combining system prompt and the user question" do
      system_prompt_context = "[{page_url: \"link_1\", " \
                              "page_title: \"Title\", " \
                              "page_description: \"Description\", " \
                              "context_headings: [\"Heading 1\", \"Heading 2\"], " \
                              "context_content: \"<p>Some content</p><a href=\\\"link_2\\\">What is a tax?</a>\", llm_instructions: \"Some instructions\"}]"
      expected_message_history = [
        { role: "system", content: "System prompt. #{system_prompt_context}" },
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
      let(:unused_search_result) { build(:weighted_search_result, _id: "2", score: 0.5, exact_path: "/vat-rates#vat-rates") }

      it "calls OpenAI chat endpoint and assigns the correct values to the context's answer" do
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expected_structured_answer = hash_including(
          "response" => hash_including_openai_response_with_tool_call("generate_answer_using_retrieved_contexts"),
          "link_token_mapping" => {
            "link_1" => "https://www.test.gov.uk/vat-rates#vat-basics",
            "link_2" => "https://www.test.gov.uk/what-is-tax",
          },
        )
        expect(context.answer.llm_responses["structured_answer"]).to match(expected_structured_answer)
        expect(context.answer.message.squish).to eq(
          "VAT (Value Added Tax) is a [tax][1] applied to most goods and services in the UK. [1]: https://www.test.gov.uk/what-is-tax",
        )
        expect(context.answer.status).to eq("answered")
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
        allow(Clock).to receive(:monotonic_time).and_return(100.0, 101.5)
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        described_class.call(context)

        expect(context.answer.metrics["structured_answer"]).to eq({
          duration: 1.5,
          llm_prompt_tokens: 13,
          llm_completion_tokens: 7,
          llm_cached_tokens: 10,
          model: "gpt-4o-mini-2024-07-18",
        })
      end

      it "aborts the pipeline when only an unknown source is used" do
        structured_response = {
          answer: "Here is an answer.",
          answered: true,
          sources_used: ["/unknown-path"],
        }.to_json
        stub_openai_chat_completion_structured_response(
          expected_message_history,
          structured_response,
        )

        expect { described_class.call(context) }.to throw_symbol(:abort)
          .and change { context.answer.sources.first.used }.to(false)
      end

      context "and answered is 'false'" do
        include_examples "llm cannot answer the question", {
          answer: "Sorry i cannot answer that question.",
          answered: false,
          sources_used: %w[link_1],
        }.to_json
      end

      context "and sources_used is empty" do
        include_examples "llm cannot answer the question", {
          answer: "Here is an answer.",
          answered: true,
          sources_used: [],
        }.to_json
      end
    end
  end
end
