class AddPerformanceAnalysisConsentBooleanToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :performance_analysis_consent, :boolean, default: false, null: false
  end
end
