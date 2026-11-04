class AddSuggestedPromptToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :suggested_prompt, :boolean, default: false, null: false
  end
end
