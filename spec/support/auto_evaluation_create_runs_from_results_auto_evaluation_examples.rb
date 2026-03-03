shared_examples "auto_evaluation create runs from auto evaluation results" do |run_association|
  describe ".create_runs_from_auto_evaluation_results" do
    let(:success_run_result) { build(:auto_evaluation_result, score: 0.9) }
    let(:failure_run_result) { build(:auto_evaluation_result, score: 0.3, status: "failure") }
    let(:error_run_result) { build(:auto_evaluation_result, :with_error) }

    let(:results) { [success_run_result, failure_run_result, error_run_result] }
    let(:answer) { create(:answer) }
    let(:answer_id) { answer.id }

    it "creates runs within a transaction with correct attributes and associations" do
      answer = Answer.includes(run_association).find(answer_id)
      expect(described_class).to receive(:transaction).and_call_original

      expect {
        described_class.create_runs_from_auto_evaluation_results(answer, results, run_association)
      }.to change(answer.public_send(run_association), :count).by(3)

      first_run, second_run, third_run = answer.reload.public_send(run_association)

      expect(first_run).to have_attributes(success_run_result.to_h)
      expect(second_run).to have_attributes(failure_run_result.to_h)
      expect(third_run).to have_attributes(error_run_result.to_h)
    end
  end
end
