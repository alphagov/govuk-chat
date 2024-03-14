RSpec.describe UserInputHelper do
  describe "#escaped_simple_format" do
    it "escapes the output" do
      string = "This is a string with <script>alert('XSS')</script> in it."
      expected_result = "<p>This is a string with &lt;script&gt;alert('XSS')&lt;/script&gt; in it.</p>"

      expect(escaped_simple_format(string)).to eq(expected_result)
    end

    it "correctly formats line breaks" do
      string = "How much tax should I be paying?\n\n<br>What are the tax brackets? \n What is the tax free allowance?"
      expected_result = "<p>How much tax should I be paying?</p>\n" \
      "\n" \
      "<p>&lt;br&gt;What are the tax brackets? \n" \
      "<br /> What is the tax free allowance?</p>"

      expect(escaped_simple_format(string)).to eq(expected_result)
    end

    it "correctly adds html_options" do
      string = "How much tax should I be paying?"
      expected_result = "<p class=\"govuk-body\">How much tax should I be paying?</p>"

      expect(escaped_simple_format(string, { class: "govuk-body" })).to eq(expected_result)
    end
  end
end
