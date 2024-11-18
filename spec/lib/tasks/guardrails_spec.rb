RSpec.describe "rake guardrails tasks" do
  describe "guardrails:evaluate_guardrails" do
    let(:task_name) { "guardrails:evaluate_guardrails" }
    let(:dataset_path) { "spec/support/files/answer_guardrails_examples.csv" }

    before do
      Rake::Task[task_name].reenable
      stub_openai_output_guardrail("", 'True | "1"')
    end

    it "aborts if an invalid guardrail type is provided" do
      expect { Rake::Task[task_name].invoke("invalid_guardrail_type", dataset_path) }
        .to output(/Invalid guardrail type/).to_stderr
        .and raise_error(SystemExit)
    end

    it "aborts if no dataset_path is provided" do
      expect { Rake::Task[task_name].invoke(:answer_guardrails) }
        .to output(/No dataset path provided/).to_stderr
        .and raise_error(SystemExit)
    end

    it "aborts if the dataset_path is invalid" do
      expect { Rake::Task[task_name].invoke(:answer_guardrails, "invalid_path") }
        .to output(/No file found at #{Rails.root.join('invalid_path')}/).to_stderr
        .and raise_error(SystemExit)
    end

    context "when given an output path" do
      it "runs successfully, outputs summary, and saves the results to a file with the given path" do
        temp = Tempfile.new
        begin
          examples = CSV.read(Rails.root.join(dataset_path), headers: true).length
          expect(Guardrails::MultipleChecker).to receive(:call).exactly(examples).times.and_call_original

          expect { Rake::Task[task_name].invoke(:answer_guardrails, dataset_path, temp.path) }
            .to output(/count=>[\s\S]*Full results/).to_stdout
          results = JSON.parse(File.read(temp.path))

          expect(results).to be_a(Hash)
          expect(results).to include("count", "model")
          expect(results["model"]).to eq(Guardrails::MultipleChecker::OPENAI_MODEL)

          # Average token count depends on the number of examples, so we'll just
          # check the presence of a value here so the tests won't fail when the
          # CSV file changes
          expect(results["average_prompt_token_count"]).to be_a(Integer)
          expect(results["max_prompt_token_count"]).to eq(13)

          first_example = results["false_positives"][0]
          expect(first_example["actual"]).to eq('True | "1"')
        ensure
          temp.close
          temp.unlink
        end
      end
    end

    context "without an output path" do
      it "outputs the full structure to the console" do
        expect { Rake::Task[task_name].invoke(:question_routing_guardrails, dataset_path) }
          .to output(/count=>[\s\S]*failures=>/).to_stdout
      end
    end
  end

  describe "guardrails:print_prompts" do
    let(:task_name) { "guardrails:print_prompts" }

    before do
      Rake::Task[task_name].reenable
      allow(Guardrails::MultipleChecker).to receive(:collated_prompts).and_call_original
    end

    it "aborts if an invalid guardrail type is provided" do
      expect { Rake::Task[task_name].invoke("invalid_guardrail_type") }
        .to output(/Invalid guardrail type/).to_stderr
        .and raise_error(SystemExit)
    end

    it "calls MultipleChecker.collated_prompts with the correct arg and outputs to stdout" do
      expect { Rake::Task[task_name].invoke("answer_guardrails") }.to output(/# System prompt/).to_stdout
      expect(Guardrails::MultipleChecker).to have_received(:collated_prompts).with(:answer_guardrails)
    end
  end
end
