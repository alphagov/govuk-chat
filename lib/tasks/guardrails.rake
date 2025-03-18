namespace "guardrails" do
  desc "Output guardrail evaluation using Guardrails::MultipleChecker"
  task :evaluate_guardrails, %i[guardrail_type dataset_path output_path llm_provider] => :environment do |_, args|
    guardrail_type = args[:guardrail_type].to_sym
    valid_guardrail_types = %i[answer_guardrails question_routing_guardrails]
    if guardrail_type.blank? || valid_guardrail_types.exclude?(guardrail_type)
      abort("Invalid guardrail type. Valid guardrail types are #{valid_guardrail_types.to_sentence}")
    end

    dataset_path = args[:dataset_path]
    if dataset_path.blank?
      abort("No dataset path provided")
    end

    dataset_absolute_path = Pathname.new(Dir.pwd).join(args[:dataset_path])
    unless File.exist?(dataset_absolute_path)
      abort("No file found at #{dataset_absolute_path}")
    end

    output_path = args[:output_path]
    llm_provider = (args[:llm_provider] || :openai).to_sym
    valid_providers = %i[openai claude]
    if valid_providers.exclude?(llm_provider)
      abort("Invalid LLM provider. Valid providers are #{valid_providers.to_sentence}")
    end

    true_eval = ->(v) { v != "False | None" }

    prompt_token_counts = []

    results = Guardrails::Evaluation.call(dataset_absolute_path, true_eval:) do |input|
      result = Guardrails::MultipleChecker.call(input, guardrail_type, llm_provider)
      prompt_token_counts << result.llm_prompt_tokens
      result.llm_guardrail_result
    rescue Guardrails::MultipleChecker::ResponseError => e
      prompt_token_counts << e.llm_prompt_tokens
      "ERR: #{e.llm_response}"
    end

    average_prompt_token_count = prompt_token_counts.sum / prompt_token_counts.size

    results.merge!(
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
  task :print_prompts, %i[guardrail_type llm_provider] => :environment do |_, args|
    guardrail_type = args[:guardrail_type].to_sym
    valid_guardrail_types = %i[answer_guardrails question_routing_guardrails]
    if guardrail_type.blank? || valid_guardrail_types.exclude?(guardrail_type)
      abort("Invalid guardrail type. Valid guardrail types are #{valid_guardrail_types.to_sentence}")
    end

    llm_provider = (args[:llm_provider] || :openai).to_sym
    valid_providers = %i[openai claude]
    if valid_providers.exclude?(llm_provider)
      abort("Invalid LLM provider. Valid providers are #{valid_providers.to_sentence}")
    end

    prompt = Guardrails::MultipleChecker.collated_prompts(guardrail_type, llm_provider)
    puts prompt
  end
end
