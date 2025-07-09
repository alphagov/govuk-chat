class AddUnclearIntentAndRequiresAccountData < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :question_routing_label, "unclear_intent"
    add_enum_value :question_routing_label, "requires_account_data"
  end
end
