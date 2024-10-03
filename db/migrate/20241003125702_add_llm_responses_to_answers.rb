class AddLlmResponsesToAnswers < ActiveRecord::Migration[7.2]
  def change
    add_column :answers, :llm_responses, :jsonb
  end
end
