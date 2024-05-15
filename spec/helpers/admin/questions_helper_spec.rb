RSpec.describe Admin::QuestionsHelper do
  describe "#format_answer_status_as_tag" do
    it "raises an error for unknown statuses" do
      expect { helper.format_answer_status_as_tag("unknown") }
        .to raise_error(RuntimeError, "Unknown status: unknown")
    end

    it "returns a valid tag for each status enum value" do
      Answer.statuses.each_value do |value|
        expect { helper.format_answer_status_as_tag(value) }.not_to raise_error
      end
    end

    context "when the status passed in does not have a corresponding description" do
      it "returns a tag with the status as the title attribute" do
        tag = helper.format_answer_status_as_tag("success")
        expect(tag).to eq('<span title="Success" class="govuk-tag govuk-tag--green">Success</span>')
      end

      it "returns a tag with the status as the title attribute when with_description_suffix is true" do
        tag = helper.format_answer_status_as_tag("success", with_description_suffix: true)
        expect(tag).to eq('<span title="Success" class="govuk-tag govuk-tag--green">Success</span>')
      end
    end

    context "when the status passed in has a corresponding description" do
      it "returns a tag with the status and description as the title attribute" do
        tag = helper.format_answer_status_as_tag("abort_forbidden_words")
        expect(tag).to eq('<span title="Abort - forbidden words in question" class="govuk-tag govuk-tag--orange">Abort</span>')
      end

      it "returns a tag and a visible description when with_description_suffix is true" do
        tag = helper.format_answer_status_as_tag("abort_forbidden_words", with_description_suffix: true)
        expected_output = '<span title="Abort - forbidden words in question" class="govuk-tag govuk-tag--orange">Abort</span>' \
                          " - forbidden words in question"
        expect(tag).to eq(expected_output)
      end
    end
  end

  describe "#question_show_summary_list_rows" do
    let(:question) { create(:question) }

    it "returns the correct rows when question is unanswered" do
      result = helper.question_show_summary_list_rows(question, nil)
      expected_keys = [
        "Conversation id",
        "Question number",
        "Question id",
        "Question created at",
        "Question",
        "Show search results",
        "Status",
      ]

      expect(returned_keys(result)).to match_array(expected_keys)
    end

    it "returns the correct rows when the question has an answer" do
      answer = build_stubbed(:answer)
      result = helper.question_show_summary_list_rows(question, answer)
      expected_keys = [
        "Conversation id",
        "Question number",
        "Question id",
        "Question created at",
        "Question",
        "Rephrased question",
        "Show search results",
        "Status",
        "Answer created at",
        "Answer",
      ]

      expect(returned_keys(result)).to match_array(expected_keys)
    end

    it "returns an error message row if the answer has an error message" do
      answer = build_stubbed(:answer, error_message: "An error message")
      result = helper.question_show_summary_list_rows(question, answer)

      expect(returned_keys(result)).to include("Error message")
    end

    it "returns a sources row when the question has sources" do
      answer = build_stubbed(:answer, sources: [build_stubbed(:answer_source)])
      result = helper.question_show_summary_list_rows(question, answer)

      expect(returned_keys(result)).to include("Sources")
    end
  end

  def returned_keys(result)
    result.map { |row| row[:field] }
  end
end
