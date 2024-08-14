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
    let(:model_name) { OutputGuardrails::FewShot::OPENAI_MODEL }
    let(:output_file) { Rails.root.join("tmp/output_guardrails_results_#{model_name}.json") }

    before do
      Rake::Task[task_name].reenable
      allow(OutputGuardrails::FewShot).to receive(:call).and_return(llm_response)
      File.delete(output_file) if File.exist?(output_file)
    end

    after do
      File.delete(output_file) if File.exist?(output_file)
    end

    it "runs successfully, outputs results, and saves the results to a file with the model name in the path" do
      expect { Rake::Task[task_name].invoke }.to output.to_stdout

      expect(File).to exist(output_file)

      results = JSON.parse(File.read(output_file))

      expect(results).to be_a(Hash)
      expect(results).to include("count", "model")
      expect(results["model"]).to eq(model_name)

      expect(OutputGuardrails::FewShot).to have_received(:call).at_least(100).times
    end
  end
end
