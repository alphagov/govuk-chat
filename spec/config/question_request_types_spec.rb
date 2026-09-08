RSpec.describe "Question request type configuration" do
  it "can locate the question request types in the private repo configuration" do
    config = Rails.configuration.question_request_types

    expect(config)
      .to be_an(Array)
      .and be_present
  end
end
