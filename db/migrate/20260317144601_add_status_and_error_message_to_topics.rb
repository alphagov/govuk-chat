class AddStatusAndErrorMessageToTopics < ActiveRecord::Migration[8.0]
  def change
    create_enum :answer_analysis_topics_status, %w[success error]
    change_table :answer_analysis_topics, bulk: true do |t|
      t.enum :status, default: "success", null: false, enum_type: "answer_analysis_topics_status"
      t.string :error_message
    end
  end
end
