class AddAbortQuestionRoutingStatus < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "abort_question_routing"
    add_enum_value :status, "error_question_routing"
  end
end
