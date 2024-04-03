class AddStatusToAnswers < ActiveRecord::Migration[7.1]
  def up
    create_enum :status, %w[success error_non_specific error_answer_service_error]

    change_table :answers, bulk: true do |t|
      t.enum :status, enum_type: "status", null: false
      t.string :error_message
    end
  end

  def down
    change_table :answers, bulk: true do |t|
      t.remove :status
      t.remove :error_message
    end

    drop_enum :status
  end
end
