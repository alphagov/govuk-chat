RSpec.describe AnswerAnalysis::CoherenceJob do
  include ActiveJob::TestHelper

  let(:results) { [build(:auto_evaluation_score_result)] }

  before do
    allow(AutoEvaluation::Coherence)
      .to receive(:call).and_return(*results)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it_behaves_like "a job in queue", "default"
  it_behaves_like "a job that adheres to the auto_evaluation quota", AutoEvaluation::Coherence
  it_behaves_like "a job that retries on errors", Aws::Errors::ServiceError do
    before do
      allow(AutoEvaluation::Coherence)
        .to receive(:call)
        .and_raise(Aws::Errors::ServiceError.new(nil, "error"))
    end
  end
  it_behaves_like "a job that creates runs from score results",
                  AutoEvaluation::Coherence,
                  AnswerAnalysis::CoherenceRun,
                  :coherence_runs
end
