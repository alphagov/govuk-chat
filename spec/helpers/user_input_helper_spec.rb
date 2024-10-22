RSpec.describe UserInputHelper do
  describe "#escaped_simple_format" do
    it "escapes the output" do
      string = "This is a string with <script>alert('XSS')</script> in it."
      expected_result = "<p>This is a string with &lt;script&gt;alert('XSS')&lt;/script&gt; in it.</p>"

      expect(helper.escaped_simple_format(string)).to eq(expected_result)
    end

    it "correctly formats line breaks" do
      string = "How much tax should I be paying?\n\n<br>What are the tax brackets? \n What is the tax free allowance?"
      expected_result = "<p>How much tax should I be paying?</p>\n" \
      "\n" \
      "<p>&lt;br&gt;What are the tax brackets? \n" \
      "<br /> What is the tax free allowance?</p>"

      expect(helper.escaped_simple_format(string)).to eq(expected_result)
    end

    it "correctly adds html_options" do
      string = "How much tax should I be paying?"
      expected_result = "<p class=\"govuk-body\">How much tax should I be paying?</p>"

      expect(helper.escaped_simple_format(string, { class: "govuk-body" })).to eq(expected_result)
    end
  end

  describe "remaining_questions_copy" do
    it "is nil if the user is nil" do
      expect(helper.remaining_questions_copy(nil)).to be_nil
    end

    it "is nil if the user can ask an unlimited number of questions" do
      user = build(:early_access_user, individual_question_limit: 0)

      expect(helper.remaining_questions_copy(user)).to be_nil
    end

    it "is nil if the user has not reached the warning threshold" do
      allow(Rails.configuration.conversations).to receive_messages(
        max_questions_per_user: 50,
        question_warning_threshold: 20,
      )
      user = build(:early_access_user, questions_count: 5)

      expect(helper.remaining_questions_copy(user)).to be_nil
    end

    it "returns the remaining question count if the user has reached the warning threshold" do
      allow(Rails.configuration.conversations).to receive_messages(
        max_questions_per_user: 50,
        question_warning_threshold: 20,
      )
      user = build(:early_access_user, questions_count: 40)

      expect(helper.remaining_questions_copy(user)).to eq("10 messages left")
    end
  end
end
