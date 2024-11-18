namespace "guardrails" do
  desc "Output guardrail evaluation using Guardrails::MultipleChecker - supply a file path to write to JSON"
  task :evaluate_answer_guardrails, %i[output_path] => :environment do |_, args|
    output_path = args[:output_path]
    file_path = Rails.root.join("lib/data/output_guardrails/answer_guardrails_examples.csv")

    model_name = Guardrails::MultipleChecker::OPENAI_MODEL
    true_eval = ->(v) { v != "False | None" }

    prompt_token_counts = []

    results = Guardrails::Evaluation.call(file_path, true_eval:) do |input|
      result = Guardrails::MultipleChecker.call(input, :answer_guardrails)
      prompt_token_counts << result.llm_token_usage["prompt_tokens"]
      result.llm_guardrail_result
    rescue Guardrails::MultipleChecker::ResponseError => e
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

  desc "Print prompts for a guardrail type"
  task :print_prompts, %i[guardrail_type] => :environment do |_, args|
    guardrail_type = args[:guardrail_type].to_sym
    valid_guardrail_types = %i[answer_guardrails question_routing_guardrails]
    if guardrail_type.blank? || valid_guardrail_types.exclude?(guardrail_type)
      abort("Invalid guardrail type. Valid guardrail types are #{valid_guardrail_types.to_sentence}")
    end

    prompt = Guardrails::MultipleChecker.collated_prompts(guardrail_type)
    puts prompt
  end
end
