RSpec.describe "rake guardrails tasks" do
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

    it "aborts if an invalid llm_provider is provided" do
      expect { Rake::Task[task_name].invoke("answer_guardrails", "invalid_provider") }
        .to output(/Invalid LLM provider/).to_stderr
        .and raise_error(SystemExit)
    end

    shared_examples "prints prompts" do |provider|
      it "calls MultipleChecker.collated_prompts with the correct args and outputs to stdout" do
        expect { Rake::Task[task_name].invoke("answer_guardrails", provider) }.to output(/# System prompt/).to_stdout
        expected_provider = provider&.to_sym || :openai
        expect(Guardrails::MultipleChecker).to have_received(:collated_prompts).with(:answer_guardrails, expected_provider)
      end
    end

    it_behaves_like "prints prompts", nil # Test default OpenAI provider
    it_behaves_like "prints prompts", "openai"
    it_behaves_like "prints prompts", "claude"
  end
end
