RSpec.describe "rake guardrails tasks" do
  describe "guardrails:print_prompts" do
    let(:task_name) { "guardrails:print_prompts" }

    before do
      Rake::Task[task_name].reenable
      allow(AnswerComposition::MultipleGuardrail::Prompt).to receive(:collated).and_call_original
    end

    it "aborts if an invalid guardrail type is provided" do
      expect { Rake::Task[task_name].invoke("invalid_guardrail_type") }
        .to output(/Invalid guardrail type/).to_stderr
        .and raise_error(SystemExit)
    end

    it "calls MultipleChecker.collated with the correct args and outputs to stdout" do
      expect { Rake::Task[task_name].invoke("answer_guardrails") }.to output(/# System prompt/).to_stdout
      expect(AnswerComposition::MultipleGuardrail::Prompt).to have_received(:collated).with(:answer_guardrails)
    end
  end
end
