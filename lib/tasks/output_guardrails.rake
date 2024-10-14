namespace "output_guardrails" do
  desc "Output guardrail evaluation using OutputGuardrails::FewShot - supply a file path to write to JSON"
  task :evaluate_fewshot, %i[output_path] => :environment do |_, args|
    output_path = args[:output_path]
    file_path = Rails.root.join("lib/data/output_guardrails/fewshot_examples.csv")

    model_name = OutputGuardrails::FewShot::OPENAI_MODEL
    true_eval = ->(v) { v != "False | None" }

    prompt_token_counts = []

    results = OutputGuardrails::Evaluation.call(file_path, true_eval:) do |input|
      result = OutputGuardrails::FewShot.call(input)
      prompt_token_counts << result.llm_token_usage["prompt_tokens"]
      result.llm_guardrail_result
    rescue OutputGuardrails::FewShot::ResponseError => e
      prompt_token_counts << e.llm_token_usage["prompt_tokens"]
      "ERR: #{e.llm_response}"
    end

    average_prompt_token_count = prompt_token_counts.sum / prompt_token_counts.size

    results.merge!(
      model: model_name,
      average_prompt_token_count:,
      max_prompt_token_count: prompt_token_counts.max,
    )

    if output_path.nil?
      pp results
    else
      pp results.slice(:model, :count, :percent_correct, :precision, :recall, :average_latency)
      File.write(output_path, JSON.pretty_generate(results))

      puts "Full results have been saved to: #{output_path}"
    end
  end
end
