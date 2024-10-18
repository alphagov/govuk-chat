class RemoveAnswersWithNotGovukRecordsQuestionRoutingLabel < ActiveRecord::Migration[7.2]
  class Answer < ApplicationRecord
    enum :question_routing_label,
         {
           content_not_govuk: "content_not_govuk",
         }
  end

  def up
    Answer.where(question_routing_label: :content_not_govuk).destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
