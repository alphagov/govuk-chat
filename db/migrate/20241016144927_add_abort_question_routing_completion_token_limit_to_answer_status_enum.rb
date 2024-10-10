class AddAbortQuestionRoutingCompletionTokenLimitToAnswerStatusEnum < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_question_routing_token_limit"
  end
end
