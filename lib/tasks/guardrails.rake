namespace "guardrails" do
  desc "Output guardrail evaluation using Guardrails::FewShot"
  task evaluate_fewshot: :environment do
    file_path = Rails.root.join("lib/data/guardrails_fewshot_examples.csv")
    pp OutputGuardrails::Evaluation.call(file_path) { |input| OutputGuardrails::FewShot.call(input).llm_response }
  end
end
