RSpec.describe "Question routing labels" do
  it "has a human-readable label for each question routing label in the LLM config" do
    llm_config = Rails.configuration.govuk_chat_private.llm_prompts.question_routing
    llm_labels = llm_config[:classifications].map { |classification| classification[:name] }

    label_config = Rails.configuration.question_routing_labels

    expect(llm_labels - label_config.keys).to be_empty
  end

  it "defines a use_answer property for each question routing label" do
    label_config = Rails.configuration.question_routing_labels
    expect(label_config.values).to all(match(hash_including("use_answer" => boolean)))
  end

  it "specifies an array of canned_responses for each label other than genuine_rag" do
    labels_except_genuine_rag = Rails.configuration.question_routing_labels.except("genuine_rag")
    only_strings_matcher = match(all(be_a(String)))
    expect(labels_except_genuine_rag.values).to all(
      match(hash_including("canned_responses" => be_present.and(only_strings_matcher))),
    )
  end

  it "defines a valid answer_status property for each question routing label" do
    answer_statuses = Rails.configuration.question_routing_labels.values
      .map { |config| config["answer_status"] }
      .compact
      .uniq

    valid_statuses = Answer.statuses.keys

    expect(answer_statuses).to all(be_in(valid_statuses))
  end
end
