RSpec.describe AnswerAnalysis::ContextRelevancyJob do
  include ActiveJob::TestHelper

  let(:results) { [build(:auto_evaluation_result)] }

  before do
    allow(AutoEvaluation::ContextRelevancy)
      .to receive(:call).and_return(*results)
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it_behaves_like "a job in queue", "default"
  it_behaves_like "a job that adheres to the auto_evaluation quota", AutoEvaluation::ContextRelevancy
  it_behaves_like "a job that retries on aws sdk errors", AutoEvaluation::ContextRelevancy
  it_behaves_like "a job that creates runs from score results",
                  AutoEvaluation::ContextRelevancy,
                  AnswerAnalysis::ContextRelevancyRun,
                  :context_relevancy_runs
end
