RSpec.describe "rake guardrails tasks" do
  describe "output_guardrails:evaluate_fewshot" do
    let(:task_name) { "output_guardrails:evaluate_fewshot" }
    let(:false_response) do
      OutputGuardrails::FewShot::Result.new(
        llm_response: "False | None",
        triggered: false,
        guardrails: [],
        llm_token_usage: {},
      )
    end
    let(:true_response) do
      OutputGuardrails::FewShot::Result.new(
        llm_response: 'True | "1"',
        triggered: true,
        guardrails: %w[sensitive_financial_matters],
        llm_token_usage: {},
      )
    end
    let(:model_name) { OutputGuardrails::FewShot::OPENAI_MODEL }

    before do
      Rake::Task[task_name].reenable
      allow(OutputGuardrails::FewShot).to receive(:call).and_return(false_response, true_response)
    end

    context "when given an output path" do
      it "runs successfully, outputs summary, and saves the results to a file with the given path" do
        temp = Tempfile.new
        begin
          expect { Rake::Task[task_name].invoke(temp.path) }.to output(/count=>[\s\S]*Full results/).to_stdout
          results = JSON.parse(File.read(temp.path))

          expect(results).to be_a(Hash)
          expect(results).to include("count", "model")
          expect(results["model"]).to eq(model_name)

          examples = CSV.read(Rails.root.join("lib/data/output_guardrails/fewshot_examples.csv"), headers: true).length
          expect(OutputGuardrails::FewShot).to have_received(:call).exactly(examples).times
        ensure
          temp.close
          temp.unlink
        end
      end
    end

    context "without an output path" do
      it "outputs the full structure to the console" do
        expect { Rake::Task[task_name].invoke }.to output(/count=>[\s\S]*failures=>/).to_stdout
      end
    end
  end
end
