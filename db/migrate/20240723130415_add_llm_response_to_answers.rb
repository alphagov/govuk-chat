class AddLlmResponseToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_column :answers, :llm_response, :string
  end
end
