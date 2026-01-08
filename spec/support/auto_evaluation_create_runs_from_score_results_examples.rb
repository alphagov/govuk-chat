shared_examples "auto_evaluation create runs from score results" do |run_association|
  describe ".create_runs_from_score_results" do
    let(:first_run_result) { build(:auto_evaluation_score_result, score: 0.8) }
    let(:second_run_result) { build(:auto_evaluation_score_result, score: 0.9) }
    let(:results) { [first_run_result, second_run_result] }
    let(:answer) { create(:answer) }
    let(:answer_id) { answer.id }

    it "creates runs within a transaction with correct attributes and associations" do
      answer = Answer.includes(run_association).find(answer_id)
      expect(described_class).to receive(:transaction).and_call_original

      expect {
        described_class.create_runs_from_score_results(answer, results, run_association)
      }.to change(answer.public_send(run_association), :count).by(2)

      first_run, second_run = answer.reload.public_send(run_association)

      expect(first_run).to have_attributes(first_run_result.to_h.except(:success))
      expect(second_run).to have_attributes(second_run_result.to_h.except(:success))
    end
  end
end
