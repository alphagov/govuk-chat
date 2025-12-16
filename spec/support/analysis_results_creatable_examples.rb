shared_examples "analysis results creatable" do |aggregate_association, run_class, result_class|
  describe "#create_mean_aggregate_and_score_runs" do
    let(:first_run_result) do
      result_class.new(
        score: 0.80,
        reason: "The answer is relevant to the question.",
        success: true,
        llm_responses: {
          "response_1" => { "content" => "LLM response content 1" },
          "response_2" => { "content" => "LLM response content 2" },
        },
        metrics: {
          "metric_1" => { "detail" => "Metric detail 1" },
          "metric_2" => { "detail" => "Metric detail 2" },
        },
      )
    end
    let(:second_run_result) do
      result_class.new(
        score: 0.90,
        reason: "The answer mostly addresses the question.",
        success: true,
        llm_responses: {
          "response_3" => { "content" => "LLM response content 3" },
          "response_4" => { "content" => "LLM response content 4" },
        },
        metrics: {
          "metric_3" => { "detail" => "Metric detail 3" },
          "metric_4" => { "detail" => "Metric detail 4" },
        },
      )
    end
    let(:results) { [first_run_result, second_run_result] }
    let(:answer) { create(:answer) }
    let(:answer_id) { answer.id }

    it "creates an aggregate with correct mean score" do
      answer = Answer.includes(aggregate_association).find(answer_id)
      expect { described_class.create_mean_aggregate_and_score_runs(answer, results) }
        .to change(described_class, :count).by(1)

      answer = Answer.includes(aggregate_association).find(answer_id)
      expect(answer.answer_relevancy_aggregate.mean_score.round(2)).to eq(0.85)
    end

    it "creates runs with correct attributes and associations" do
      answer = Answer.includes("#{aggregate_association}": :runs).find(answer_id)

      expect {
        described_class.create_mean_aggregate_and_score_runs(answer, results)
      }.to change(run_class, :count).by(2)

      first_run, second_run = answer.reload.public_send(aggregate_association).runs.order(:created_at)

      expect(first_run).to have_attributes(
        score: first_run_result.score.round(2),
        reason: first_run_result.reason,
        llm_responses: first_run_result.llm_responses,
        metrics: first_run_result.metrics,
      )
      expect(second_run).to have_attributes(
        score: second_run_result.score.round(2),
        reason: second_run_result.reason,
        llm_responses: second_run_result.llm_responses,
        metrics: second_run_result.metrics,
      )
    end
  end
end
