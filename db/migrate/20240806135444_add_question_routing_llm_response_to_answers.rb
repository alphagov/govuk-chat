class AddQuestionRoutingLlmResponseToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :answers, :question_routing_llm_response, :text, null: true
  end
end
