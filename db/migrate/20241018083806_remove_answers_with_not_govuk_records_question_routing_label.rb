class RemoveAnswersWithNotGovukRecordsQuestionRoutingLabel < ActiveRecord::Migration[7.2]
  def up
    if Answer.question_routing_labels.keys.include?("content_not_govuk")
      Answer.where(question_routing_label: :content_not_govuk).destroy_all
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
