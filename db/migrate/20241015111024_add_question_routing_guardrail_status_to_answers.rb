class AddQuestionRoutingGuardrailStatusToAnswers < ActiveRecord::Migration[7.2]
  def change
    change_table :answers, bulk: true do |t|
      t.enum :question_routing_guardrails_status, null: true, enum_type: "guardrails_status"
      t.column :question_routing_guardrails_failures, :string, array: true, default: []
    end
  end
end
