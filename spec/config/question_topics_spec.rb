RSpec.describe "Question topic configuration" do
  it "can locate the question topics in the private repo configuration" do
    config = Rails.configuration.question_topics

    expect(config)
      .to be_an(Array)
      .and be_present
  end
end
