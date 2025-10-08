RSpec.describe DailyApiActivityMessage do
  describe ".message" do
    let(:web_conversation) { create(:conversation, source: :web) }
    let(:api_conversation) { create(:conversation, source: :api) }
    let(:yesterday) { 1.day.ago }

    def create_answer(status, created_at, conversation)
      create(:answer, status:, created_at:, question: build(:question, conversation:))
    end

    def admin_url(status)
      today = yesterday.to_date + 1

      url_params = {
        source: :api,
        start_date_params: { day: yesterday.day, month: yesterday.month, year: yesterday.year },
        end_date_params: { day: today.day, month: today.month, year: today.year },
        host: Plek.external_url_for(:chat),
      }

      Rails.application.routes.url_helpers.admin_questions_url(
        url_params.merge(status:),
      )
    end

    around do |example|
      travel_to(Time.zone.local(2025, 1, 1, 13, 0, 0)) do
        example.run
      end
    end

    it "builds the message with zero questions" do
      message = described_class.new(Date.yesterday).message
      expect(message).to eq("Yesterday GOV.UK Chat API received 0 questions.")
    end

    it "only includes non-zero question counts" do
      create_answer(:clarification, yesterday + 2.hours, api_conversation)
      expected_message = <<~MSG.strip
        Yesterday GOV.UK Chat API received 1 question:

        - <#{admin_url(:clarification)}|1 Clarification - question routing requested more information>
      MSG

      message = described_class.new(Date.yesterday).message
      expect(message).to eq(expected_message)
    end

    def label_for_status(status)
      Rails.configuration.answer_statuses[status][:label_and_description]
    end

    it "builds the message with various question counts" do
      create_answer(:answered, 2.days.ago, api_conversation)
      create_answer(:answered, 2.days.ago, web_conversation)

      2.times do
        create_answer(:answered, yesterday + 4.hours, api_conversation)
      end

      3.times do
        create_answer(:clarification, yesterday + 2.hours, api_conversation)
      end

      2.times do
        create_answer(:unanswerable_no_govuk_content, yesterday + 2.hours, api_conversation)
      end

      4.times do
        create_answer(:error_non_specific, yesterday + 4.hours, api_conversation)
      end

      create_answer(:guardrails_forbidden_terms, yesterday + 4.hours, api_conversation)

      expected_message = <<~MSG.strip
        Yesterday GOV.UK Chat API received 12 questions:

        - <#{admin_url(:error_non_specific)}|4 #{label_for_status(:error_non_specific)}>
        - <#{admin_url(:clarification)}|3 #{label_for_status(:clarification)}>
        - <#{admin_url(:answered)}|2 Answered>
        - <#{admin_url(:unanswerable_no_govuk_content)}|2 #{label_for_status(:unanswerable_no_govuk_content)}>
        - <#{admin_url(:guardrails_forbidden_terms)}|1 #{label_for_status(:guardrails_forbidden_terms)}>
      MSG

      puts expected_message
      message = described_class.new(Date.yesterday).message
      expect(message).to eq(expected_message)
    end
  end
end
