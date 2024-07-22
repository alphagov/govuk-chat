class AddGuardrailsStatusToAnswer < ActiveRecord::Migration[7.1]
  def change
    create_enum "output_guardrails_status", %w[pass fail error]
  end
end
