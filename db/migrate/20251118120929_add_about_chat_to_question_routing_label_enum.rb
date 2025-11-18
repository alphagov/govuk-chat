class AddAboutChatToQuestionRoutingLabelEnum < ActiveRecord::Migration[8.0]
  def change
    add_enum_value :question_routing_label, "about_chat"
  end
end
