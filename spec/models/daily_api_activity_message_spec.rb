RSpec.describe DailyApiActivityMessage do
  describe "#message" do
    let(:web_conversation) { create(:conversation, source: :web) }
    let(:api_conversation) { create(:conversation, source: :api) }
    let(:yesterday) { 1.day.ago }

    def create_question(status, created_at, conversation)
      answer = status == :pending ? nil : build(:answer, status:)
      create(:question, conversation:, created_at:, answer:)
    end

    def admin_url(status = nil)
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

    def label_for_status(status)
      config = Rails.configuration.answer_statuses.fetch(status)
      config[:label_and_description] || config[:label]
    end

    around do |example|
      travel_to(Time.zone.local(2025, 1, 1, 13, 0, 0)) do
        example.run
      end
    end

    describe "monitoring rota" do
      before do
        allow(Rails.configuration.govuk_chat_private).to receive(:experiment_monitoring_rota).and_return(
          monitoring_rota_config,
        )
      end

      context "when there is no rota config available" do
        let(:monitoring_rota_config) { nil }

        it "omits the rota summary" do
          message = described_class.new(Date.yesterday).message
          expect(message).not_to include("it's your turn to be responsible for monitoring Chat")
        end
      end

      context "when there is rota config available for the current day and the following day" do
        let(:monitoring_rota_config) do
          {
            rota: {
              "2025-01-01" => "Alice",
              "2025-01-02" => "Bob",
            },
            slack_usernames: {
              "Alice" => "alice",
              "Bob" => "bob",
            },
          }
        end

        it "includes the rota summary" do
          message = described_class.new(Date.yesterday).message

          expected_message = <<~MSG.strip
            Yesterday GOV.UK Chat API received 0 questions.

            Alice (@alice) - it's your turn to be responsible for monitoring Chat.
            Bob (@bob) - it's your turn tomorrow. Let us know if you're unavailable for your slot so we can find a backup person.

            Guidance on the daily monitoring of Chat can be found <https://docs.google.com/document/d/1OijsFLKh7azOmOFMWlyZWoqW4PNmE-gffXlPE-qito8/edit?tab=t.0|here>.
          MSG

          expect(message).to eq(expected_message)
        end
      end

      context "when there is rota config available for the current day but not the following day" do
        let(:monitoring_rota_config) do
          {
            rota: {
              "2025-01-01" => "Alice",
            },
            slack_usernames: {
              "Alice" => "alice",
              "Bob" => "bob",
            },
          }
        end

        it "includes the rota summary for today only" do
          message = described_class.new(Date.yesterday).message
          expected_message = <<~MSG.strip
            Yesterday GOV.UK Chat API received 0 questions.

            Alice (@alice) - it's your turn to be responsible for monitoring Chat.

            Guidance on the daily monitoring of Chat can be found <https://docs.google.com/document/d/1OijsFLKh7azOmOFMWlyZWoqW4PNmE-gffXlPE-qito8/edit?tab=t.0|here>.
          MSG

          expect(message).to eq(expected_message)
        end
      end

      context "when there is no rota config available for the current day" do
        let(:monitoring_rota_config) do
          {
            rota: {
              "2025-01-02" => "Alice",
              "2025-01-03" => "Bob",
            },
          }
        end

        it "omits the rota summary" do
          message = described_class.new(Date.yesterday).message
          expect(message).not_to include("it's your turn to be responsible for monitoring Chat")
        end
      end
    end

    describe "questions status" do
      it "builds the message with zero questions" do
        message = described_class.new(Date.yesterday).message
        expect(message).to eq("Yesterday GOV.UK Chat API received 0 questions.")
      end

      it "only includes non-zero question counts" do
        create_question(:clarification, yesterday + 2.hours, api_conversation)
        expected_message = <<~MSG.strip
          Yesterday GOV.UK Chat API received <#{admin_url}|1 question>:

          - <#{admin_url(:clarification)}|1 #{label_for_status(:clarification)}>
        MSG

        message = described_class.new(Date.yesterday).message
        expect(message).to eq(expected_message)
      end

      it "builds the message with various question counts" do
        create_question(:answered, 2.days.ago, api_conversation)

        2.times do
          create_question(:answered, yesterday + 4.hours, api_conversation)
          create_question(:answered, yesterday, web_conversation)
        end

        3.times do
          create_question(:clarification, yesterday + 2.hours, api_conversation)
        end

        2.times do
          create_question(:unanswerable_no_govuk_content, yesterday + 2.hours, api_conversation)
        end

        4.times do
          create_question(:error_non_specific, yesterday + 4.hours, api_conversation)
        end

        create_question(:pending, yesterday + 4.hours, api_conversation)
        create_question(:guardrails_forbidden_terms, yesterday + 4.hours, api_conversation)

        expected_message = <<~MSG.strip
          Yesterday GOV.UK Chat API received <#{admin_url}|13 questions>:

          - <#{admin_url(:error_non_specific)}|4 #{label_for_status(:error_non_specific)}>
          - <#{admin_url(:clarification)}|3 #{label_for_status(:clarification)}>
          - <#{admin_url(:answered)}|2 #{label_for_status(:answered)}>
          - <#{admin_url(:unanswerable_no_govuk_content)}|2 #{label_for_status(:unanswerable_no_govuk_content)}>
          - <#{admin_url(:guardrails_forbidden_terms)}|1 #{label_for_status(:guardrails_forbidden_terms)}>
          - <#{admin_url(:pending)}|1 #{label_for_status(:pending)}>
        MSG

        message = described_class.new(Date.yesterday).message
        expect(message).to eq(expected_message)
      end

      context "when conversations are associated with an end user id" do
        it "includes the number of distinct end users associated with the conversations" do
          conversations = Array.new(3) do
            build(:conversation, source: :api, end_user_id: SecureRandom.uuid)
          end

          2.times { create_question(:answered, yesterday, conversations[0]) }
          2.times { create_question(:answered, yesterday, conversations[1]) }
          create_question(:answered, yesterday, conversations[2])

          expected_message = "Yesterday GOV.UK Chat API received <#{admin_url}|5 questions> " \
                             "from 3 end users:"

          message = described_class.new(Date.yesterday).message
          expect(message).to include(expected_message)
        end

        it "has the correct plural for a singular end user" do
          end_user_conversation = build(:conversation, source: :api, end_user_id: SecureRandom.uuid)
          4.times { create_question(:answered, yesterday, end_user_conversation) }

          expected_message = "Yesterday GOV.UK Chat API received <#{admin_url}|4 questions> " \
                             "from 1 end user:"

          message = described_class.new(Date.yesterday).message
          expect(message).to include(expected_message)
        end
      end
    end
  end
end
