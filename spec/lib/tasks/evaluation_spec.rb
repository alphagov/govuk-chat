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

  describe "generate_answer" do
    let(:task_name) { "evaluation:generate_answer" }
    let(:input) { "What is the current VAT rate?" }

    before do
      Rake::Task[task_name].reenable
    end

    it_behaves_like "a task requiring an input"

    it "outputs the answer as JSON to stdout" do
      answer = build(:answer)
      answer_strategy = "claude_structured_answer"

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(INPUT: input) do
        answer_json = answer.serialize_for_evaluation.to_json
        expect { Rake::Task[task_name].invoke(answer_strategy) }
          .to output("#{answer_json}\n").to_stdout
      end

      expect(AnswerComposition::Composer)
        .to have_received(:call)
        .with(an_object_having_attributes(message: input,
                                          conversation: an_instance_of(Conversation),
                                          answer_strategy: answer_strategy))
    end

    it "warns when an answer_strategy argument isn't given" do
      answer = build(:answer)
      default_answer_strategy = Rails.configuration.answer_strategy

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke }
          .to output.to_stdout
          .and output("No answer strategy argument provided, using #{default_answer_strategy}\n").to_stderr
      end

      expect(AnswerComposition::Composer)
        .to have_received(:call)
        .with(an_object_having_attributes(message: input,
                                          conversation: an_instance_of(Conversation),
                                          answer_strategy: default_answer_strategy))
    end

    it "warns when an answer has an error status" do
      error_message = "Something is broken"
      answer = build(:answer, status: :error_answer_service_error, error_message:)

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(INPUT: input) do
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
        answer = build(:answer, :with_sources)
        answer_json = answer.serialize_for_evaluation.to_json
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
        expect { Rake::Task[task_name].invoke("openai") }
          .to output("#{answer_json}\n").to_stdout
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
        answer = build(:answer,
                       question_routing_label: "unclear_intent",
                       question_routing_confidence_score: 0.2,
                       message: "Sorry, can you say that again?")
        allow(AnswerComposition::PipelineRunner).to receive(:call).and_return(answer)
        expected_output = {
          classification: "unclear_intent",
          confidence_score: 0.2,
          answer: "Sorry, can you say that again?",
        }
        expect { Rake::Task[task_name].invoke("openai") }
          .to output("#{expected_output.to_json}\n").to_stdout
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
          build(
            :weighted_search_result,
            exact_path: "/path1",
            plain_content: "Content 1",
            score: 1.5,
            weighted_score: 1.0,
          ),
          build(
            :weighted_search_result,
            exact_path: "/path2",
            plain_content: "Content 2",
            score: 0.9,
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
        result = AutoEvaluation::TopicTagger::Result.new(
          primary_topic: "tax",
          secondary_topic: "benefits",
          metrics: {},
          llm_response: {},
        )
        allow(AutoEvaluation::TopicTagger).to receive(:call).with(input).and_return(result)

        expect { Rake::Task[task_name].invoke }
          .to output("#{result.to_json}\n").to_stdout
      end
    end
  end

  describe "batch_process" do
    let(:task_name) { "evaluation:batch_process" }
    let(:usage_regex) { /#{Regexp.escape('Usage: evaluation:batch_process[task_name, *task_args]')}/ }
    let(:questions) { ["First question", "Second question"] }
    let(:responses) do
      questions.map do |question|
        { "input" => question, "output" => { "some" => "data" } }
      end
    end
    let(:expected_output) { responses.map(&:to_json).join("\n") }
    let(:batch_task) { "my_task" }
    let(:batch_task_args) { %w[arg1 arg2] }

    before do
      Rake::Task[task_name].reenable

      responses = questions.map do |question|
        { "input" => question, "output" => { "some" => "data" } }
      end

      allow(Evaluation::BatchTaskProcesser)
        .to receive(:call)
        .and_return(responses)
    end

    it "requires a task_name argument" do
      expect { Rake::Task[task_name].invoke(nil) }.to raise_error(usage_regex)
    end

    it "requires an INPUT PATH env var" do
      expect { Rake::Task[task_name].invoke(batch_task) }.to raise_error(usage_regex)
    end

    it "delegates running a rake task to Evaluation::BatchTaskProcesser" do
      ClimateControl.modify(INPUT_PATH: "file.yaml") do
        expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
          .to output.to_stdout

        expect(Evaluation::BatchTaskProcesser)
          .to have_received(:call)
          .with("file.yaml", batch_task, batch_task_args, concurrency: Integer)
      end
    end

    it "writes progress to stdout" do
      allow(Evaluation::BatchTaskProcesser)
        .to receive(:call)
        .and_return(responses)
        .and_yield([], 2, 1)
        .and_yield([], 2, 2)

      ClimateControl.modify(INPUT_PATH: "file.yaml") do
        expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
          .to output(%r{#{Regexp.escape('(1 / 2)')}\n#{Regexp.escape('(2 / 2)')}}).to_stdout
      end
    end

    it "writes warnings yielded to stderr" do
      allow(Evaluation::BatchTaskProcesser)
        .to receive(:call)
        .and_return(responses)
        .and_yield(["Warning 1"], 2, 1)
        .and_yield(["Warning 2", "Warning 3"], 2, 2)

      ClimateControl.modify(INPUT_PATH: "file.yaml") do
        expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
          .to output.to_stdout
          .and output(/(Warning (1|2|3)\n?){3}/).to_stderr
      end
    end

    context "when given an OUTPUT_PATH env var" do
      it "writes the output to the OUTPUT_PATH file given" do
        tempfile = Tempfile.new

        ClimateControl.modify(INPUT_PATH: "file.yaml", OUTPUT_PATH: tempfile.path) do
          output_confirmation = "Written to #{tempfile.path}"

          expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
            .to output(/#{Regexp.escape(output_confirmation)}/).to_stdout

          expect(File.read(tempfile.path)).to eq(expected_output)
        end

        tempfile.close!
      end
    end

    context "when not given an OUTPUT_PATH env var" do
      it "writes the output to stdout" do
        ClimateControl.modify(INPUT_PATH: "file.yaml") do
          expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
            .to output(/#{Regexp.escape(expected_output)}/).to_stdout
        end
      end
    end

    context "when given a CONCURRENCY env var" do
      it "outputs to stdout and passes it to Evaluation::BatchTaskProcesser" do
        ClimateControl.modify(INPUT_PATH: "file.yaml", CONCURRENCY: "20") do
          expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
            .to output(/Running with a concurrency of 20/).to_stdout

          expect(Evaluation::BatchTaskProcesser)
            .to have_received(:call)
            .with("file.yaml", batch_task, batch_task_args, concurrency: 20)
        end
      end
    end

    context "when not given a CONCURRENCY env var" do
      it "defaults to a concurrency of 10" do
        ClimateControl.modify(INPUT_PATH: "file.yaml") do
          expect { Rake::Task[task_name].invoke(batch_task, *batch_task_args) }
            .to output(/Running with a concurrency of 10/).to_stdout

          expect(Evaluation::BatchTaskProcesser)
            .to have_received(:call)
            .with("file.yaml", batch_task, batch_task_args, concurrency: 10)
        end
      end
    end
  end

  describe "generate_answer_relevancy_evaluation" do
    let(:task_name) { "evaluation:generate_answer_relevancy_evaluation" }
    let(:question_message) { "What is the current VAT rate?" }
    let(:answer) { build(:answer) }
    let(:evaluation_result) do
      AutoEvaluation::Result.new(
        score: 0.7,
        reason: "Most statements are relevant.",
        success: true,
        llm_responses: {},
        metrics: {},
      )
    end

    before do
      Rake::Task[task_name].reenable

      allow(AnswerComposition::PipelineRunner)
        .to receive(:call)
        .with(
          question: an_instance_of(Question),
          pipeline: [
            AnswerComposition::Pipeline::Claude::QuestionRouter,
            AnswerComposition::Pipeline::SearchResultFetcher,
            AnswerComposition::Pipeline::Claude::StructuredAnswerComposer,
          ],
        )
        .and_return(answer)

      allow(AutoEvaluation::AnswerRelevancy)
        .to receive(:call)
        .with(
          question_message:,
          answer_message: answer.message,
        )
        .and_return(evaluation_result)
    end

    it_behaves_like "a task requiring an input"

    it "outputs the evaluation result as JSON to stdout" do
      ClimateControl.modify(INPUT: question_message) do
        expected_result_output = {
          score: evaluation_result.score,
          reason: evaluation_result.reason,
          success: evaluation_result.success,
          llm_responses: evaluation_result.llm_responses,
          metrics: evaluation_result.metrics,
        }.to_json

        expect { Rake::Task[task_name].invoke }
          .to output("#{expected_result_output}\n").to_stdout
      end
    end

    context "when an answer has an error status" do
      let(:error_message) { "Answer generation failed" }
      let(:answer) { build(:answer, status: :error_answer_service_error, error_message:) }

      it "warns the user and outputs the error message" do
        ClimateControl.modify(INPUT: question_message) do
          expected_stderr = "Warning: answer has an error status: #{answer.status}\n#{error_message}\n"
          expect { Rake::Task[task_name].invoke }
            .to raise_error(SystemExit)
            .and output(expected_stderr).to_stderr
        end
      end
    end
  end
end
