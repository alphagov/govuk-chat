namespace "guardrails" do
  desc "Print prompts for a guardrail type"
  task :print_prompts, %i[guardrail_type] => :environment do |_, args|
    guardrail_type = args[:guardrail_type].to_sym
    valid_guardrail_types = %i[answer_guardrails question_routing_guardrails]
    if guardrail_type.blank? || valid_guardrail_types.exclude?(guardrail_type)
      abort("Invalid guardrail type. Valid guardrail types are #{valid_guardrail_types.to_sentence}")
    end

    prompt = Guardrails::MultipleChecker.collated_prompts(guardrail_type, :claude)
    puts prompt
  end
end
