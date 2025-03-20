RSpec.describe "rake evaluation tasks" do
  describe "generate_report" do
    let(:task_name) { "evaluation:generate_report" }
    let(:evaluation_data) do
      [
        { question: "First question", llm_answer: "First answer" },
        { question: "Second question", llm_answer: "Second answer" },
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

    it "generates the results as JSONL and prints them" do
      expect { Rake::Task[task_name].invoke("input.yml") }
        .to output(/#{jsonl}/).to_stdout
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

      allow(AnswerComposition::Composer)
        .to receive(:call)
        .with(an_instance_of(Question))
        .and_return(answer)

      ClimateControl.modify(QUESTION: "What is the current VAT rate?") do
        answer_json = { message: answer.message }.to_json
        expect { Rake::Task[task_name].invoke }
          .to output("#{answer_json}\n").to_stdout
      end
    end
  end

  describe "generate_jailbreak_guardrail_response" do
    let(:task_name) { "evaluation:generate_jailbreak_guardrail_response" }
    let(:input) { "Is this a jailbreak?" }

    before { Rake::Task[task_name].reenable }

    it "requires a INPUT env var" do
      expect { Rake::Task[task_name].invoke("openai") }
        .to raise_error("Requires an INPUT env var")
    end

    it "requires a provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke }
          .to raise_error("Requires a provider")
      end
    end

    it "requires a known provider" do
      ClimateControl.modify(INPUT: input) do
        expect { Rake::Task[task_name].invoke("unknown") }
          .to raise_error("Unsupported provider: unknown")
      end
    end

    it "outputs the response as JSON to stdout" do
      ClimateControl.modify(INPUT: input) do
        result = Guardrails::JailbreakChecker::Result.new(
          triggered: true,
          llm_response: {},
          llm_prompt_tokens: 100,
          llm_completion_tokens: 100,
          llm_cached_tokens: 0,
        )
        allow(Guardrails::JailbreakChecker).to receive(:call).with(input).and_return(result)
        expect { Rake::Task[task_name].invoke("openai") }
          .to output("#{result.to_json}\n").to_stdout
      end
    end
  end
end
