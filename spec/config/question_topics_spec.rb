RSpec.describe "Question topic configuration" do
  it "can locate the question topics in the private repo configuration" do
    config = Rails.configuration
                   .govuk_chat_private
                   .llm_prompts
                   .claude
                   .topic_tagger
                   .dig("tool_spec", "input_schema", "$defs", "govuk_topic_tags", "enum")

    expect(config)
      .to be_an(Array)
      .and be_present
  end
end
