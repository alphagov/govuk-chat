class AmendAnswerAnalysisRunTables < ActiveRecord::Migration[8.0]
  def change
    create_enum :answer_analysis_run_status, %w[success failure error]
    models = %i[
      answer_analysis_coherence_runs
      answer_analysis_answer_relevancy_runs
      answer_analysis_context_relevancy_runs
      answer_analysis_faithfulness_runs
    ]

    models.each do |model|
      add_column model, :status, :answer_analysis_run_status, null: false, default: "success"
      add_column model, :error_message, :string
      change_column_null model, :score, true
      change_column_null model, :reason, true
      remove_column model, :success, :boolean, null: false, default: true
    end
  end
end
