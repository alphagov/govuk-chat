class CreateAnswerAnalysisRequestTypes < ActiveRecord::Migration[8.1]
  def change
    create_enum :answer_analysis_request_types_status, %w[success error]

    create_table :answer_analysis_request_types, id: :uuid do |t|
      t.references :answer, type: :uuid, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :primary_request_type
      t.string :secondary_request_type
      t.decimal :confidence
      t.string :reasoning
      t.enum :status, default: "success", null: false, enum_type: "answer_analysis_request_types_status"
      t.string :error_message
      t.jsonb :metrics, default: {}, null: false
      t.jsonb :llm_responses, default: {}, null: false

      t.timestamps
    end
  end
end
