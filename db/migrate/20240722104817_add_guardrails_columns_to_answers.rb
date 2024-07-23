class AddGuardrailsColumnsToAnswers < ActiveRecord::Migration[7.1]
  def change
    change_table :answers, bulk: true do |t|
      t.enum :output_guardrail_status, null: true, enum_type: "output_guardrails_status"
      t.column :output_guardrail_failures, :string, array: true, default: []
      t.string :output_guardrail_llm_response, null: true
    end
  end
end
