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
        tag = helper.format_answer_status_as_tag("abort_timeout")
        expect(tag).to eq('<span title="Abort - no answer after configured timeout" class="govuk-tag govuk-tag--orange">Abort</span>')
      end

      it "returns a tag and a visible description when with_description_suffix is true" do
        tag = helper.format_answer_status_as_tag("abort_timeout", with_description_suffix: true)
        expected_output = '<span title="Abort - no answer after configured timeout" class="govuk-tag govuk-tag--orange">Abort</span>' \
                          " - no answer after configured timeout"
        expect(tag).to eq(expected_output)
      end
    end
  end

  describe "#question_show_summary_list_rows" do
    let(:question) { create(:question) }

    it "returns the correct rows when question is unanswered" do
      result = helper.question_show_summary_list_rows(question, nil, 1, 1)
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
      answer = create(:answer, sources: [])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)
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
        "Question routing label",
        "Question routing confidence score",
        "Question routing LLM Response",
        "LLM Response",
        "Guardrails status",
        "Guardrails triggered",
        "Guardrails LLM response",
      ]

      expect(returned_keys(result)).to match_array(expected_keys)
    end

    it "returns an error message row if the answer has an error message" do
      answer = create(:answer, sources: [], error_message: "An error message")
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Error message")
    end

    it "returns a used sources row when the answer has sources" do
      answer = create(:answer, sources: [create(:answer_source)])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Used sources")
    end

    it "returns an unused sources row when the answer has unused sources" do
      answer = create(:answer, sources: [create(:answer_source, used: false)])
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Unused sources")
    end

    it "returns feedback rows when the answer has feedback" do
      answer = create(:answer, :with_feedback)
      answer = answer_from_db(answer)
      result = helper.question_show_summary_list_rows(question, answer, 1, 1)

      expect(returned_keys(result)).to include("Feedback created at", "Feedback")
    end
  end

  def returned_keys(result)
    result.map { |row| row[:field] }
  end

  def answer_from_db(answer)
    Answer.includes(:sources, :feedback).find(answer.id)
  end
end
