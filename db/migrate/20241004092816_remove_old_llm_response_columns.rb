class RemoveOldLlmResponseColumns < ActiveRecord::Migration[7.2]
  def up
    change_table :answers, bulk: true do |t|
      t.remove :question_routing_llm_response
      t.remove :llm_response
      t.remove :output_guardrail_llm_response
    end
  end

  def down
    change_table :answers, bulk: true do |t|
      t.text :question_routing_llm_response
      t.string :llm_response
      t.string :output_guardrail_llm_response
    end
  end
end
