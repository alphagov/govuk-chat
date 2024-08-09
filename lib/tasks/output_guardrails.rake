namespace "output_guardrails" do
  desc "Output guardrail evaluation using OutputGuardrails::FewShot"
  task evaluate_fewshot: :environment do
    file_path = Rails.root.join("lib/data/output_guardrails/fewshot_examples.csv")
    true_eval = ->(v) { v != "False | None" }
    pp OutputGuardrails::Evaluation.call(file_path, true_eval:) { |input| OutputGuardrails::FewShot.call(input).llm_response }
  end
end
