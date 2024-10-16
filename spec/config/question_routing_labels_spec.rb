RSpec.describe "Question routing labels" do
  it "has a human-readable label for each question routing label in the LLM config" do
    llm_config = Rails.configuration.llm_prompts.question_routing
    llm_labels = llm_config[:classifications].map { |classification| classification[:name] }

    label_config = Rails.configuration.question_routing_labels

    expect(llm_labels - label_config.keys).to be_empty
  end

  it "defines a use_answer property for each question routing label" do
    label_config = Rails.configuration.question_routing_labels
    expect(label_config.values).to all(match(hash_including("use_answer" => boolean)))
  end
end
