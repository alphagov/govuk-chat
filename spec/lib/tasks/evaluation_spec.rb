RSpec.describe "rake evaluation tasks" do
  shared_examples "a task requiring input and provider" do
    it "requires an INPUT env var" do
      expect { Rake::Task[task_name].invoke("openai") }
        .to raise_error("Requires an INPUT env var")
    end

    it "requires a provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke }
          .to raise_error("Requires a provider")
      end
    end
  end

  shared_examples "a task requiring a known provider" do
    it "raises an error when given an unknown provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke("super-duper-ai") }
          .to raise_error("Unexpected provider super-duper-ai")
      end
    end
  end

  shared_examples "a task requiring an input" do
    it "requires an INPUT env var" do
      expect { Rake::Task[task_name].invoke }
        .to raise_error("Requires an INPUT env var")
    end
  end

  describe "generate_report" do
    let(:task_name) { "evaluation:generate_report" }
    let(:evaluation_data) do
      [
        { question: "First question", answer: { "message" => "First answer" }, retrieved_context: [] },
        { question: "Second question", answer: { "message" => "Second answer" }, retrieved_context: [] },
      ]
    end
    let(:jsonl) do
      evaluation_data.map(&:to_json).join("\n")
    end

    before do
      Rake::Task[task_name].reenable

      allow(Evaluation::ReportGenerator).to receive(:call).and_return(evaluation_data)
    end

    it "raises an error if input_path is not specified" do
      expect { Rake::Task[task_name].invoke }
        .to raise_error(/Usage: evaluation:generate_report/)
    end

    it "outputs the answer_strategy to stdout" do
      expect { Rake::Task[task_name].invoke("input.yml") }
        .to output(/Generating report with answer strategy: \S*/).to_stdout
    end

    it "generates the results as JSONL and prints them" do
      expect { Rake::Task[task_name].invoke("input.yml") }
        .to output(/#{Regexp.escape(jsonl)}/).to_stdout
    end

    it "generates the results as JSONL and writes them to a file" do
      temp = Tempfile.new
      output_path = temp.path

      begin
        expect { Rake::Task[task_name].invoke("input.yml", output_path) }
          .to output(/Written to #{output_path}/).to_stdout

        expect(File.read(output_path)).to eq(jsonl)
      ensure
        temp.close
        temp.unlink
      end
    end

    it "sets GOVUK_WEBSITE_ROOT, if not set, to specify https://www.gov.uk links" do
      ClimateControl.modify(GOVUK_WEBSITE_ROOT: nil) do
        expect { Rake::Task[task_name].invoke("input.yml") }.to output.to_stdout

        expect(ENV["GOVUK_WEBSITE_ROOT"]).to eq("https://www.gov.uk")
      end
    end

    it "doesn't change GOVUK_WEBSITE_ROOT when already set" do
      ClimateControl.modify(GOVUK_WEBSITE_ROOT: "http://test.gov.uk") do
        expect { Rake::Task[task_name].invoke("input.yml") }.to output.to_stdout

        expect(ENV["GOVUK_WEBSITE_ROOT"]).to eq("http://test.gov.uk")
      end
    end
  end

  describe "generate_answer" do
    let(:task_name) { "evaluation:generate_answer" }

    before do
      Rake::Task[task_name].reenable
    end

    it "requires a QUESTION env var" do
      expect { Rake::Task[task_name].invoke }
        .to raise_error("requires a QUESTION env var")
    end

    it "outputs the answer as JSON to stdout" do
      answer = build(:answer)
      question = "What is the current VAT rate?"
      answer_strategy = "claude_structured_answer"

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(QUESTION: question) do
        answer_json = { message: answer.message }.to_json
        expect { Rake::Task[task_name].invoke(answer_strategy) }
          .to output("#{answer_json}\n").to_stdout
      end

      expect(AnswerComposition::Composer)
        .to have_received(:call)
        .with(an_object_having_attributes(message: question,
                                          conversation: an_instance_of(Conversation),
                                          answer_strategy: answer_strategy))
    end

    it "warns when an answer_strategy argument isn't given" do
      answer = build(:answer)
      question = "What is the current VAT rate?"
      default_answer_strategy = Rails.configuration.answer_strategy

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(QUESTION: question) do
        expect { Rake::Task[task_name].invoke }
          .to output.to_stdout
          .and output("No answer strategy argument provided, using #{default_answer_strategy}\n").to_stderr
      end

      expect(AnswerComposition::Composer)
        .to have_received(:call)
        .with(an_object_having_attributes(message: question,
                                          conversation: an_instance_of(Conversation),
                                          answer_strategy: default_answer_strategy))
    end

    it "warns when an answer has an erorr status" do
      error_message = "Something is broken"
      answer = build(:answer, status: :error_answer_service_error, error_message:)

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(QUESTION: "What is the current VAT rate?") do
        expected_message = "Warning: answer has an error status: error_answer_service_error\n#{error_message}\n"
        expect { Rake::Task[task_name].invoke("claude_structured_answer") }
          .to output.to_stdout
          .and output(expected_message).to_stderr
      end
    end
  end

  describe "generate_jailbreak_guardrail_response" do
    let(:task_name) { "evaluation:generate_jailbreak_guardrail_response" }
    let(:input) { "Is this a jailbreak?" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring input and provider"
    it_behaves_like "a task requiring a known provider"

    context "when a successful check occurs" do
      it "outputs the response as JSON to stdout with a success key" do
        ClimateControl.modify(INPUT: input) do
          result = Guardrails::JailbreakChecker::Result.new(
            triggered: true,
            llm_response: {},
            llm_prompt_tokens: 100,
            llm_completion_tokens: 100,
            llm_cached_tokens: 0,
            model: Guardrails::OpenAI::JailbreakChecker::OPENAI_MODEL,
          )
          allow(Guardrails::JailbreakChecker).to receive(:call).with(input, :openai).and_return(result)
          expected = { success: result }.to_json
          expect { Rake::Task[task_name].invoke("openai") }
            .to output("#{expected}\n").to_stdout
        end
      end
    end

    context "when a response error is returned" do
      it "outputs the error as JSON to stdout with a response_error key" do
        ClimateControl.modify(INPUT: input) do
          error = Guardrails::JailbreakChecker::ResponseError.new(
            "Error parsing jailbreak guardrails response",
            llm_guardrail_result: "Unexpected",
            llm_response: {},
            llm_prompt_tokens: 100,
            llm_completion_tokens: 100,
            llm_cached_tokens: 0,
            model: Guardrails::OpenAI::JailbreakChecker::OPENAI_MODEL,
          )
          allow(Guardrails::JailbreakChecker).to receive(:call).with(input, :openai).and_raise(error)

          expected = { response_error: error }.to_json
          expect { Rake::Task[task_name].invoke("openai") }
            .to output("#{expected}\n").to_stdout
        end
      end
    end
  end

  describe "generate_output_guardrail_response" do
    let(:task_name) { "evaluation:generate_output_guardrail_response" }
    let(:input) { "input" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring input and provider"

    it "requires a guardrail type" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke("openai") }
          .to raise_error("Requires a guardrail type")
      end
    end

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        result = build(:guardrails_multiple_checker_result, :pass)
        allow(Guardrails::MultipleChecker).to receive(:call).with(input, :answer_guardrails, :openai).and_return(result)
        expect { Rake::Task[task_name].invoke("openai", "answer_guardrails") }
          .to output("#{result.to_json}\n").to_stdout
      end
    end
  end

  describe "generate_rag_structured_answer_response" do
    let(:task_name) { "evaluation:generate_rag_structured_answer_response" }
    let(:input) { "Question" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring an input"

    it "requires an llm_provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke }
          .to raise_error("Requires an llm provider")
      end
    end

    it "raises if given an unknown llm provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke("super-ai") }
          .to raise_error("Unexpected llm provider super-ai")
      end
    end

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        answer = build(:answer)
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
        expect { Rake::Task[task_name].invoke("openai") }
          .to output("#{answer.to_json}\n").to_stdout
      end
    end

    context "when provider is openai" do
      it "calls the pipeline runner with the tasks to generate an OpenAI structured answer" do
        ClimateControl.modify(INPUT: input) do
          answer = build(:answer)
          allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)

          expect { Rake::Task[task_name].invoke("openai") }
            .to output.to_stdout

          expect(AnswerComposition::PipelineRunner)
            .to have_received(:call)
            .with(question: instance_of(Question), pipeline: [
              AnswerComposition::Pipeline::SearchResultFetcher,
              AnswerComposition::Pipeline::OpenAI::StructuredAnswerComposer,
            ])
        end
      end
    end

    context "when provider is claude" do
      it "calls the pipeline runner with the tasks to generate a Claude structured answer" do
        ClimateControl.modify(INPUT: input) do
          answer = build(:answer)
          allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)

          expect { Rake::Task[task_name].invoke("claude") }
            .to output.to_stdout

          expect(AnswerComposition::PipelineRunner)
            .to have_received(:call)
            .with(question: instance_of(Question), pipeline: [
              AnswerComposition::Pipeline::SearchResultFetcher,
              AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
            ])
        end
      end
    end
  end

  describe "generate_question_routing_response" do
    let(:task_name) { "evaluation:generate_question_routing_response" }
    let(:input) { "Question" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring input and provider"
    it_behaves_like "a task requiring a known provider"

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        answer = build(:answer, question_routing_label: "genuine_rag", question_routing_confidence_score: 0.2)
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
        expect { Rake::Task[task_name].invoke("openai") }
          .to output("{\"classification\":\"genuine_rag\",\"confidence_score\":0.2}\n").to_stdout
      end
    end

    it "raises an error if the the answer has an error status" do
      ClimateControl.modify(INPUT: input) do
        error_message = "Oh no!"
        answer = build(:answer, status: :error_answer_service_error, error_message:)
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
        expect { Rake::Task[task_name].invoke("openai") }
          .to raise_error("Error occurred generating answer: Oh no!")
      end
    end

    context "when provider is openai" do
      it "calls the pipeline runner with the tasks to generate an OpenAI question routing response" do
        ClimateControl.modify(INPUT: input) do
          answer = build(:answer)
          allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)

          expect { Rake::Task[task_name].invoke("openai") }
            .to output.to_stdout

          expect(AnswerComposition::PipelineRunner)
            .to have_received(:call)
            .with(question: instance_of(Question), pipeline: [
              AnswerComposition::Pipeline::OpenAI::QuestionRouter,
            ])
        end
      end
    end

    context "when provider is claude" do
      it "calls the pipeline runner with the tasks to generate a Claude question routing response" do
        ClimateControl.modify(INPUT: input) do
          answer = build(:answer)
          allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)

          expect { Rake::Task[task_name].invoke("claude") }
            .to output.to_stdout

          expect(AnswerComposition::PipelineRunner)
            .to have_received(:call)
            .with(question: instance_of(Question), pipeline: [
              AnswerComposition::Pipeline::Claude::QuestionRouter,
            ])
        end
      end
    end
  end

  describe "search_results_for_question" do
    let(:task_name) { "evaluation:search_results_for_question" }
    let(:input) { "Question" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring an input"

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        search_results = [
          Search::ResultsForQuestion::WeightedResult.new(
            result: build(
              :chunked_content_search_result,
              exact_path: "/path1",
              plain_content: "Content 1",
              score: 1.5,
            ),
            weighted_score: 1.0,
          ),

          Search::ResultsForQuestion::WeightedResult.new(
            result: build(
              :chunked_content_search_result,
              exact_path: "/path2",
              plain_content: "Content 2",
              score: 0.9,
            ),
            weighted_score: 0.9,
          ),
        ]
        result_set = Search::ResultsForQuestion::ResultSet.new(
          results: search_results,
          rejected_results: [],
          metrics: {},
        )
        allow(Search::ResultsForQuestion).to receive(:call).with(input).and_return(result_set)

        expected_output = [
          {
            exact_path: "/path1",
            plain_content: "Content 1",
            weighted_score: 1.0,
            original_score: 1.5,
          },
          {
            exact_path: "/path2",
            plain_content: "Content 2",
            weighted_score: 0.9,
            original_score: 0.9,
          },
        ].to_json

        expect { Rake::Task[task_name].invoke }
          .to output("#{expected_output}\n").to_stdout
      end
    end
  end

  describe "generate_topics_for_question" do
    let(:task_name) { "evaluation:generate_topics_for_question" }
    let(:input) { "User question" }

    before { Rake::Task[task_name].reenable }

    it_behaves_like "a task requiring an input"

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        result = AnswerAnalysisGeneration::TopicTagger::Result.new(
          primary_topic: "tax",
          secondary_topic: "benefits",
          metrics: {},
          llm_response: {},
        )
        allow(AnswerAnalysisGeneration::TopicTagger).to receive(:call).with(input).and_return(result)

        expect { Rake::Task[task_name].invoke }
          .to output("#{result.to_json}\n").to_stdout
      end
    end
  end
end
