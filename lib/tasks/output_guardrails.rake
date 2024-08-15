namespace "output_guardrails" do
  desc "Output guardrail evaluation using OutputGuardrails::FewShot - supply a file path to write to JSON"
  task :evaluate_fewshot, %i[output_path] => :environment do |_, args|
    output_path = args[:output_path]
    file_path = Rails.root.join("lib/data/output_guardrails/fewshot_examples.csv")

    model_name = OutputGuardrails::FewShot::OPENAI_MODEL
    true_eval = ->(v) { v != "False | None" }

    results = OutputGuardrails::Evaluation.call(file_path, true_eval:) { |input| OutputGuardrails::FewShot.call(input).llm_response }

    results.merge!(model: model_name)

    if output_path.nil?
      pp results
    else
      pp results.slice(:model, :count, :percent_correct, :precision, :recall, :average_latency)
      File.write(output_path, JSON.pretty_generate(results))

      puts "Full results have been saved to: #{output_path}"
    end
  end
end
