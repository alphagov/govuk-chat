namespace "output_guardrails" do
  desc "Output guardrail evaluation using OutputGuardrails::FewShot"
  task evaluate_fewshot: :environment do
    file_path = Rails.root.join("lib/data/output_guardrails/fewshot_examples.csv")

    model_name = OutputGuardrails::FewShot::OPENAI_MODEL
    output_file = Rails.root.join("tmp/output_guardrails_results_#{model_name}.json")
    true_eval = ->(v) { v != "False | None" }

    results = OutputGuardrails::Evaluation.call(file_path, true_eval:) { |input| OutputGuardrails::FewShot.call(input).llm_response }

    results.merge!(model: model_name)

    sanitized_results = results.transform_values do |value|
      value.is_a?(Float) && value.nan? ? "NaN" : value
    end

    File.write(output_file, JSON.pretty_generate(sanitized_results))

    pp sanitized_results.slice(:count, :percent_correct, :precision, :recall, :average_latency, :model)

    puts "Full results have been saved to: #{output_file}"
  end
end
