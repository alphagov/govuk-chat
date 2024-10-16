RSpec.describe "rake guardrails tasks" do
  describe "guardrails:evaluate_multiple_checker" do
    let(:task_name) { "guardrails:evaluate_multiple_checker" }
    let(:false_response) do
      Guardrails::MultipleChecker::Result.new(
        llm_response: llm_response_json("False | None"),
        llm_guardrail_result: "False | None",
        triggered: false,
        guardrails: [],
        llm_token_usage: { "prompt_tokens" => 1000 },
      )
    end
    let(:true_response) do
      Guardrails::MultipleChecker::Result.new(
        llm_response: llm_response_json('True | "1"'),
        llm_guardrail_result: 'True | "1"',
        triggered: true,
        guardrails: %w[sensitive_financial_matters],
        llm_token_usage: { "prompt_tokens" => 2000 },
      )
    end
    let(:model_name) { Guardrails::MultipleChecker::OPENAI_MODEL }

    before do
      Rake::Task[task_name].reenable
      allow(Guardrails::MultipleChecker).to receive(:call).and_return(false_response, true_response)
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

          # Average token count depends on the number of examples, so we'll just
          # check the presence of a value here so the tests won't fail when the
          # CSV file changes
          expect(results["average_prompt_token_count"]).to be_a(Integer)
          expect(results["max_prompt_token_count"]).to eq(2000)

          first_example = results["false_positives"][0]
          expect(first_example["actual"]).to eq(true_response.llm_guardrail_result)

          examples = CSV.read(Rails.root.join("lib/data/output_guardrails/multiple_checker_examples.csv"), headers: true).length
          expect(Guardrails::MultipleChecker).to have_received(:call).exactly(examples).times
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

    def llm_response_json(guardrail_result)
      {
        "message": {
          "role": "assistant",
          "content": guardrail_result,
          "refusal": nil,
        },
        "finish_reason": "stop",
      }
    end
  end
end
