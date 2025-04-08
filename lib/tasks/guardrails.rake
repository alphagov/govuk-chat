namespace "guardrails" do
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
