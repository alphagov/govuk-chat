RSpec.describe "rake guardrails tasks" do
  describe "output_guardrails:evaluate_fewshot" do
    let(:task_name) { "output_guardrails:evaluate_fewshot" }
    let(:llm_response) do
      OutputGuardrails::FewShot::Result.new(
        llm_response: "False | None",
        triggered: false,
        guardrails: [],
      )
    end

    before do
      Rake::Task[task_name].reenable
      allow(OutputGuardrails::FewShot).to receive(:call).and_return(llm_response)
    end

    it "runs successfully and outputs results" do
      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(OutputGuardrails::FewShot).to have_received(:call).at_least(100).times
    end
  end
end
