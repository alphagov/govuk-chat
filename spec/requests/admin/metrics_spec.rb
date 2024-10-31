RSpec.describe "Admin::MetricsController" do
  # Prevent flaky tests if tests run at turn of hour or day
  around { |example| freeze_time { example.run } }

  describe "GET :index" do
    it "defaults to rendering last 24 hours" do
      get admin_metrics_path
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-secondary-navigation__list-item--current",
                          text: "Last 24 hours")
    end

    it "accepts a parameter to render last 7 days" do
      get admin_metrics_path(period: "last_7_days")
      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to have_selector(".gem-c-secondary-navigation__list-item--current",
                          text: "Last 7 days")
    end
  end

  describe "GET :early_access_users" do
    it "renders a successful JSON response" do
      get admin_metrics_early_access_users_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the combined current and deleted early access users by source and hour" do
      create_list(:early_access_user, 5, created_at: 4.hours.ago, source: :admin_added)
      create_list(:early_access_user, 2, created_at: 1.hour.ago, source: :admin_added)
      create_list(:early_access_user, 3, created_at: 1.hour.ago, source: :instant_signup)
      create_list(:deleted_early_access_user, 2, user_created_at: 1.hour.ago, user_source: :instant_signup)
      create(:early_access_user, created_at: 25.hours.ago)
      create(:deleted_early_access_user, user_created_at: 25.hours.ago)

      get admin_metrics_early_access_users_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "admin_added", "data" => counts_for_last_24_hours(hours_ago_4: 5, hours_ago_1: 2) },
        { "name" => "instant_signup", "data" => counts_for_last_24_hours(hours_ago_1: 5) },
      )
    end

    context "when period is last_7_days" do
      it "returns data of the combined current and deleted early access users by source and date" do
        create_list(:early_access_user, 5, created_at: 4.days.ago, source: :admin_added)
        create_list(:early_access_user, 2, created_at: 1.day.ago, source: :admin_added)
        create_list(:early_access_user, 3, created_at: 1.day.ago, source: :instant_signup)
        create_list(:deleted_early_access_user, 2, user_created_at: 1.day.ago, user_source: :instant_signup)

        get admin_metrics_early_access_users_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "admin_added", "data" => counts_for_last_7_days(days_ago_4: 5, days_ago_1: 2) },
          { "name" => "instant_signup", "data" => counts_for_last_7_days(days_ago_1: 5) },
        )
      end
    end
  end

  describe "GET :waiting_list_users" do
    it "renders a successful JSON response" do
      get admin_metrics_waiting_list_users_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the combined current and deleted waiting list users by source and hour" do
      create_list(:waiting_list_user, 2, created_at: 5.hours.ago, source: :admin_added)
      create(:deleted_waiting_list_user, user_created_at: 5.hours.ago, user_source: :admin_added)
      create_list(:deleted_waiting_list_user, 4, user_source: :insufficient_instant_places)
      create(:waiting_list_user, created_at: 25.hours.ago)
      create(:deleted_waiting_list_user, user_created_at: 25.hours.ago)

      get admin_metrics_waiting_list_users_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "admin_added", "data" => counts_for_last_24_hours(hours_ago_5: 3) },
        { "name" => "insufficient_instant_places", "data" => counts_for_last_24_hours(hours_ago_0: 4) },
      )
    end

    context "when period is last_7_days" do
      it "returns data of the combined current and deleted waiting list users by source and date" do
        create_list(:waiting_list_user, 2, created_at: 5.days.ago, source: :admin_added)
        create(:deleted_waiting_list_user, user_created_at: 5.days.ago, user_source: :admin_added)
        create_list(:deleted_waiting_list_user, 4, user_source: :insufficient_instant_places)

        get admin_metrics_waiting_list_users_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "admin_added", "data" => counts_for_last_7_days(days_ago_5: 3) },
          { "name" => "insufficient_instant_places", "data" => counts_for_last_7_days(days_ago_0: 4) },
        )
      end
    end
  end

  describe "GET :conversations" do
    it "renders a successful JSON response" do
      get admin_metrics_conversations_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of new conversations by hour" do
      create_list(:conversation, 4)
      create_list(:conversation, 2, created_at: 3.hours.ago)
      create(:conversation, created_at: 25.hours.ago)

      get admin_metrics_conversations_path

      expect(JSON.parse(response.body))
        .to eq(counts_for_last_24_hours(hours_ago_0: 4, hours_ago_3: 2))
    end

    context "when period is last_7_days" do
      it "returns data of new conversations by date" do
        create_list(:conversation, 2, created_at: 6.days.ago)
        create(:conversation, created_at: 2.days.ago)

        get admin_metrics_conversations_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to eq(counts_for_last_7_days(days_ago_6: 2, days_ago_2: 1))
      end
    end
  end

  describe "GET :questions" do
    it "renders a successful JSON response" do
      get admin_metrics_questions_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of questions grouped by aggregate status and hour" do
      create(:question)
      create_list(:question, 3, :with_answer, created_at: 10.hours.ago)
      create(:question, created_at: 2.hours.ago, answer: build(:answer, status: :abort_question_routing))
      create(:question, :with_answer, created_at: 26.hours.ago)

      get admin_metrics_questions_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "pending", "data" => counts_for_last_24_hours(hours_ago_0: 1) },
        { "name" => "success", "data" => counts_for_last_24_hours(hours_ago_10: 3) },
        { "name" => "abort", "data" => counts_for_last_24_hours(hours_ago_2: 1) },
      )
    end

    context "when period is last_7_days" do
      it "returns data of questions grouped by aggregate status" do
        create(:question)
        create_list(:question, 3, :with_answer, created_at: 1.day.ago)
        create(:question, created_at: 1.day.ago, answer: build(:answer, status: :abort_question_routing))

        get admin_metrics_questions_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "pending", "data" => counts_for_last_7_days(days_ago_0: 1) },
          { "name" => "success", "data" => counts_for_last_7_days(days_ago_1: 3) },
          { "name" => "abort", "data" => counts_for_last_7_days(days_ago_1: 1) },
        )
      end
    end
  end

  describe "GET :answer_feedback" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_feedback_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of answer feedback grouped by useful and hour" do
      create_list(:answer_feedback, 3, created_at: 3.hours.ago, useful: true)
      create_list(:answer_feedback, 2, created_at: 5.hours.ago, useful: false)
      create(:answer_feedback, created_at: 26.hours.ago)

      get admin_metrics_answer_feedback_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "useful", "data" => counts_for_last_24_hours(hours_ago_3: 3) },
        { "name" => "not useful", "data" => counts_for_last_24_hours(hours_ago_5: 2) },
      )
    end

    context "when period is last_7_days" do
      it "returns data of answer feedback grouped by useful label by day" do
        create_list(:answer_feedback, 3, created_at: 3.days.ago, useful: true)
        create_list(:answer_feedback, 2, created_at: 3.days.ago, useful: false)

        get admin_metrics_answer_feedback_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "useful", "data" => counts_for_last_7_days(days_ago_3: 3) },
          { "name" => "not useful", "data" => counts_for_last_7_days(days_ago_3: 2) },
        )
      end
    end
  end

  describe "GET :answer_abort_statuses" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_abort_statuses_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the occurrences each abort status over the last 24 hours" do
      create_list(:answer, 3, created_at: 8.hours.ago, status: :abort_llm_cannot_answer)
      create_list(:answer, 2, created_at: 16.hours.ago, status: :abort_question_routing)
      create(:answer, created_at: 26.hours.ago, status: :abort_question_routing)
      create(:answer, status: :success)
      create(:answer, status: :error_timeout)

      get admin_metrics_answer_abort_statuses_path

      expect(JSON.parse(response.body)).to contain_exactly(
        ["abort_llm_cannot_answer", 3],
        ["abort_question_routing", 2],
      )
    end

    context "when period is last_7_days" do
      it "returns data of answers with abort status grouped by status and day" do
        create_list(:answer, 3, created_at: 2.days.ago, status: :abort_llm_cannot_answer)
        create_list(:answer, 2, created_at: 2.days.ago, status: :abort_question_routing)
        create(:answer, status: :success)
        create(:answer, status: :error_timeout)

        get admin_metrics_answer_abort_statuses_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "abort_llm_cannot_answer", "data" => counts_for_last_7_days(days_ago_2: 3) },
          { "name" => "abort_question_routing", "data" => counts_for_last_7_days(days_ago_2: 2) },
        )
      end
    end
  end

  describe "GET :answer_error_statuses" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_error_statuses_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the occurrences each error status over the last 24 hours" do
      create_list(:answer, 5, created_at: 10.hours.ago, status: :error_non_specific)
      create_list(:answer, 3, created_at: 3.hours.ago, status: :error_timeout)
      create(:answer, created_at: 26.hours.ago, status: :error_timeout)
      create(:answer, status: :success)
      create(:answer, status: :abort_llm_cannot_answer)

      get admin_metrics_answer_error_statuses_path

      expect(JSON.parse(response.body)).to contain_exactly(
        ["error_non_specific", 5],
        ["error_timeout", 3],
      )
    end

    context "when period is last_7_days" do
      it "returns data of answers with error status grouped by status and day" do
        create_list(:answer, 5, created_at: 1.day.ago, status: :error_non_specific)
        create_list(:answer, 3, created_at: 6.days.ago, status: :error_timeout)
        create(:answer, status: :success)
        create(:answer, status: :abort_llm_cannot_answer)

        get admin_metrics_answer_error_statuses_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "error_non_specific", "data" => counts_for_last_7_days(days_ago_1: 5) },
          { "name" => "error_timeout", "data" => counts_for_last_7_days(days_ago_6: 3) },
        )
      end
    end
  end

  describe "GET :question_routing_labels" do
    it "renders a successful JSON response" do
      get admin_metrics_question_routing_labels_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the occurrences each question routing label over the last 24 hours" do
      create_list(:answer,
                  3,
                  created_at: 3.hours.ago,
                  status: :abort_question_routing,
                  question_routing_label: :about_mps)
      create_list(:answer, 4, created_at: 13.hours.ago, question_routing_label: :genuine_rag)
      create(:answer, created_at: 26.hours.ago, question_routing_label: :genuine_rag)
      create(:answer, created_at: 2.hours.ago, question_routing_label: nil)

      get admin_metrics_question_routing_labels_path

      expect(JSON.parse(response.body)).to contain_exactly(
        ["about_mps", 3],
        ["genuine_rag", 4],
      )
    end

    context "when period is last_7_days" do
      it "returns data of the question routing labels given to answers grouped by day" do
        create_list(:answer,
                    3,
                    created_at: 3.days.ago,
                    status: :abort_question_routing,
                    question_routing_label: :about_mps)
        create_list(:answer, 4, created_at: 3.days.ago, question_routing_label: :genuine_rag)
        create_list(:answer, 2, created_at: 3.days.ago, question_routing_label: nil)

        get admin_metrics_question_routing_labels_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "about_mps", "data" => counts_for_last_7_days(days_ago_3: 3) },
          { "name" => "genuine_rag", "data" => counts_for_last_7_days(days_ago_3: 4) },
        )
      end
    end
  end

  describe "GET :answer_guardrails_failures" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_guardrails_failures_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the occurrences each guardrail over the last 24 hours" do
      create_list(:answer,
                  3,
                  created_at: 2.hours.ago,
                  answer_guardrails_status: :fail,
                  answer_guardrails_failures: %w[guardrail_1])
      create_list(:answer,
                  4,
                  created_at: 10.hours.ago,
                  answer_guardrails_status: :fail,
                  answer_guardrails_failures: %w[guardrail_1 guardrail_2])
      create_list(:answer,
                  2,
                  created_at: 20.hours.ago,
                  answer_guardrails_status: :fail,
                  answer_guardrails_failures: %w[guardrail_2 guardrail_3])
      create(:answer,
             created_at: 26.hours.ago,
             answer_guardrails_status: :fail,
             answer_guardrails_failures: %w[guardrail_2 guardrail_3])

      get admin_metrics_answer_guardrails_failures_path

      expect(JSON.parse(response.body)).to contain_exactly(
        ["guardrail_1", 7],
        ["guardrail_2", 6],
        ["guardrail_3", 2],
      )
    end

    context "when period is last_7_days" do
      it "returns data of the individual occurrences of answer_guardrails_failures given to answers by day" do
        create_list(:answer,
                    3,
                    created_at: 6.days.ago,
                    answer_guardrails_status: :fail,
                    answer_guardrails_failures: %w[guardrail_1])
        create_list(:answer,
                    4,
                    created_at: 6.days.ago,
                    answer_guardrails_status: :fail,
                    answer_guardrails_failures: %w[guardrail_1 guardrail_2])
        create_list(:answer,
                    2,
                    created_at: 6.days.ago,
                    answer_guardrails_status: :fail,
                    answer_guardrails_failures: %w[guardrail_3])
        create_list(:answer,
                    5,
                    created_at: 2.days.ago,
                    answer_guardrails_status: :fail,
                    answer_guardrails_failures: %w[guardrail_1])
        create_list(:answer,
                    3,
                    created_at: 2.days.ago,
                    answer_guardrails_status: :fail,
                    answer_guardrails_failures: %w[guardrail_2 guardrail_3])

        get admin_metrics_answer_guardrails_failures_path(period: "last_7_days")

        expect(JSON.parse(response.body)).to contain_exactly(
          { "name" => "guardrail_1", "data" => counts_for_last_7_days(days_ago_6: 7, days_ago_2: 5) },
          { "name" => "guardrail_2", "data" => counts_for_last_7_days(days_ago_6: 4, days_ago_2: 3) },
          { "name" => "guardrail_3", "data" => counts_for_last_7_days(days_ago_6: 2, days_ago_2: 3) },
        )
      end
    end
  end

  def counts_for_last_24_hours(options)
    invalid_keys = options.keys.reject { |key| key.to_s =~ /^hours_ago_(1?\d|2[0-3])$/ }
    if invalid_keys.any?
      raise ArgumentError, "Invalid keys for counts_for_last_24_hours: #{invalid_keys.join(', ')}"
    end

    data = 24.times.map do |index|
      time = (Time.current - index.hours).beginning_of_hour
      count = options.fetch("hours_ago_#{index}".to_sym, 0)
      [time.to_fs(:time), count]
    end

    data.reverse
  end

  def counts_for_last_7_days(options)
    invalid_keys = options.keys.reject { |key| key.to_s =~ /^days_ago_[0-6]$/ }
    if invalid_keys.any?
      raise ArgumentError, "Invalid keys for counts_for_last_7_days: #{invalid_keys.join(', ')}"
    end

    data = 7.times.map do |index|
      date = Date.current - index
      count = options.fetch("days_ago_#{index}".to_sym, 0)
      [date.to_s, count]
    end

    data.reverse
  end
end
