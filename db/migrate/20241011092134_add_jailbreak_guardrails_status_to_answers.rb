class AddJailbreakGuardrailsStatusToAnswers < ActiveRecord::Migration[7.2]
  def change
    change_table :answers, bulk: true do |t|
      t.enum :jailbreak_guardrails_status, null: true, enum_type: "guardrails_status"
    end
  end
end
