class RenameEarlyAccessUsersQuestionLimit < ActiveRecord::Migration[7.2]
  def change
    rename_column :early_access_users, :question_limit, :individual_question_limit
  end
end
