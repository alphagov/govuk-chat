RSpec.describe "Admin::MetricsController" do
  describe "GET :index" do
    it "renders a successful response" do
      get admin_metrics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Metrics for last 7 days")
    end
  end

  describe "GET :early_access_users" do
    it "renders a successful JSON response" do
      get admin_metrics_early_access_users_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the combined current and deleted early access users by source" do
      create_list(:early_access_user, 5, created_at: 4.days.ago, source: :admin_added)
      create_list(:early_access_user, 2, created_at: 1.day.ago, source: :admin_added)
      create_list(:early_access_user, 3, created_at: 1.day.ago, source: :instant_signup)
      create_list(:deleted_early_access_user, 2, user_created_at: 1.day.ago, user_source: :instant_signup)

      get admin_metrics_early_access_users_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "admin_added", "data" => counts_for_last_7_days(days_ago_4: 5, days_ago_1: 2) },
        { "name" => "instant_signup", "data" => counts_for_last_7_days(days_ago_1: 5) },
      )
    end
  end

  describe "GET :waiting_list_users" do
    it "renders a successful JSON response" do
      get admin_metrics_waiting_list_users_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the combined current and deleted waiting list users by source" do
      create_list(:waiting_list_user, 2, created_at: 5.days.ago, source: :admin_added)
      create(:deleted_waiting_list_user, user_created_at: 5.days.ago, user_source: :admin_added)
      create_list(:deleted_waiting_list_user, 4, user_source: :insufficient_instant_places)

      get admin_metrics_waiting_list_users_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "admin_added", "data" => counts_for_last_7_days(days_ago_5: 3) },
        { "name" => "insufficient_instant_places", "data" => counts_for_last_7_days(today: 4) },
      )
    end
  end

  describe "GET :conversations" do
    it "renders a successful JSON response" do
      get admin_metrics_conversations_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of new conversations" do
      create_list(:conversation, 2, created_at: 6.days.ago)
      create(:conversation, created_at: 2.days.ago)

      get admin_metrics_conversations_path

      expect(JSON.parse(response.body)).to eq(counts_for_last_7_days(days_ago_6: 2, days_ago_2: 1))
    end
  end

  describe "GET :questions" do
    it "renders a successful JSON response" do
      get admin_metrics_questions_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of questions grouped by aggregate status" do
      create(:question)
      create_list(:question, 3, :with_answer, created_at: 1.day.ago)
      create(:question, created_at: 1.day.ago, answer: build(:answer, status: :abort_question_routing))

      get admin_metrics_questions_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "pending", "data" => counts_for_last_7_days(today: 1) },
        { "name" => "success", "data" => counts_for_last_7_days(days_ago_1: 3) },
        { "name" => "abort", "data" => counts_for_last_7_days(days_ago_1: 1) },
      )
    end
  end

  describe "GET :answer_feedback" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_feedback_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of answer feedback grouped by useful label" do
      create_list(:answer_feedback, 3, created_at: 3.days.ago, useful: true)
      create_list(:answer_feedback, 2, created_at: 3.days.ago, useful: false)

      get admin_metrics_answer_feedback_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "useful", "data" => counts_for_last_7_days(days_ago_3: 3) },
        { "name" => "not useful", "data" => counts_for_last_7_days(days_ago_3: 2) },
      )
    end
  end

  describe "GET :answer_abort_statuses" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_abort_statuses_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of answers with abort status grouped by status" do
      create_list(:answer, 3, created_at: 2.days.ago, status: :abort_llm_cannot_answer)
      create_list(:answer, 2, created_at: 2.days.ago, status: :abort_question_routing)
      create(:answer, status: :success)
      create(:answer, status: :error_timeout)

      get admin_metrics_answer_abort_statuses_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "abort_llm_cannot_answer", "data" => counts_for_last_7_days(days_ago_2: 3) },
        { "name" => "abort_question_routing", "data" => counts_for_last_7_days(days_ago_2: 2) },
      )
    end
  end

  describe "GET :answer_error_statuses" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_error_statuses_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of answers with abort status grouped by status" do
      create_list(:answer, 5, created_at: 1.day.ago, status: :error_non_specific)
      create_list(:answer, 3, created_at: 6.days.ago, status: :error_timeout)
      create(:answer, status: :success)
      create(:answer, status: :abort_llm_cannot_answer)

      get admin_metrics_answer_error_statuses_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "error_non_specific", "data" => counts_for_last_7_days(days_ago_1: 5) },
        { "name" => "error_timeout", "data" => counts_for_last_7_days(days_ago_6: 3) },
      )
    end
  end

  describe "GET :question_routing_labels" do
    it "renders a successful JSON response" do
      get admin_metrics_question_routing_labels_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the question routing labels given to answers" do
      create_list(:answer, 3, created_at: 3.days.ago, status: :abort_question_routing, question_routing_label: :content_not_govuk)
      create_list(:answer, 4, created_at: 3.days.ago, question_routing_label: :genuine_rag)
      create_list(:answer, 2, created_at: 3.days.ago, question_routing_label: nil)

      get admin_metrics_question_routing_labels_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "content_not_govuk", "data" => counts_for_last_7_days(days_ago_3: 3) },
        { "name" => "genuine_rag", "data" => counts_for_last_7_days(days_ago_3: 4) },
      )
    end
  end

  describe "GET :answer_guardrails_failures" do
    it "renders a successful JSON response" do
      get admin_metrics_answer_guardrails_failures_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to match("application/json")
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns data of the individual occurrences of answer_guardrails_failures given to answers" do
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

      get admin_metrics_answer_guardrails_failures_path

      expect(JSON.parse(response.body)).to contain_exactly(
        { "name" => "guardrail_1", "data" => counts_for_last_7_days(days_ago_6: 7, days_ago_2: 5) },
        { "name" => "guardrail_2", "data" => counts_for_last_7_days(days_ago_6: 4, days_ago_2: 3) },
        { "name" => "guardrail_3", "data" => counts_for_last_7_days(days_ago_6: 2, days_ago_2: 3) },
      )
    end
  end

private

  def counts_for_last_7_days(days_ago_6: 0,
                             days_ago_5: 0,
                             days_ago_4: 0,
                             days_ago_3: 0,
                             days_ago_2: 0,
                             days_ago_1: 0,
                             today: 0)
    data = 7.times.map do |index|
      date = Date.current - index
      count = index == 0 ? today : binding.local_variable_get("days_ago_#{index}")
      [date.to_s, count]
    end

    data.reverse
  end
end
