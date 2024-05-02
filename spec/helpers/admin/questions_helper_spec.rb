RSpec.describe Admin::QuestionsHelper do
  describe "#format_answer_status_as_tag" do
    it "returns a green tag for the success status" do
      tag = helper.format_answer_status_as_tag("success")
      expect(tag).to eq('<span class="govuk-tag govuk-tag--green">Success</span>')
    end

    it "returns a yellow pending tag when nil is passed" do
      tag = helper.format_answer_status_as_tag(nil)
      expect(tag).to eq('<span class="govuk-tag govuk-tag--yellow">Pending</span>')
    end

    it "returns an orange abort tag for abort statuses" do
      statuses = %w[abort_forbidden_words abort_no_govuk_content]

      statuses.each do |status|
        tag = helper.format_answer_status_as_tag(status)
        expect(tag).to eq('<span class="govuk-tag govuk-tag--orange">Abort</span>')
      end
    end

    it "returns an red error tag for error statuses" do
      statuses = %w[error_answer_service_error error_context_length_exceeded error_non_specific]

      statuses.each do |status|
        tag = helper.format_answer_status_as_tag(status)
        expect(tag).to eq('<span class="govuk-tag govuk-tag--red">Error</span>')
      end
    end

    it "raises an error for unknown statuses" do
      expect { helper.format_answer_status_as_tag("unknown") }.to raise_error(RuntimeError, "Unknown status: unknown")
    end

    it "returns a valid tag for each status enum value" do
      Answer.statuses.each_value do |value|
        expect { helper.format_answer_status_as_tag(value) }.not_to raise_error
      end
    end
  end
end
