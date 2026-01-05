shared_examples "auto_evaluation results creatable" do |aggregate_association, run_class|
  describe ".create_mean_aggregate_and_score_runs" do
    let(:first_run_result) { build(:auto_evaluation_score_result, score: 0.8) }
    let(:second_run_result) { build(:auto_evaluation_score_result, score: 0.9) }
    let(:results) { [first_run_result, second_run_result] }
    let(:answer) { create(:answer) }
    let(:answer_id) { answer.id }

    it "creates an aggregate with correct mean score" do
      answer = Answer.includes(aggregate_association).find(answer_id)
      expect { described_class.create_mean_aggregate_and_score_runs(answer, results) }
        .to change(described_class, :count).by(1)

      answer = Answer.includes(aggregate_association).find(answer_id)
      expect(answer.answer_relevancy_aggregate.mean_score).to eq(0.85)
    end

    it "creates runs with correct attributes and associations" do
      answer = Answer.includes("#{aggregate_association}": :runs).find(answer_id)

      expect {
        described_class.create_mean_aggregate_and_score_runs(answer, results)
      }.to change(run_class, :count).by(2)

      first_run, second_run = answer.reload.public_send(aggregate_association).runs.order(:created_at)

      expect(first_run).to have_attributes(first_run_result.to_h.except(:success))
      expect(second_run).to have_attributes(second_run_result.to_h.except(:success))
    end
  end
end
