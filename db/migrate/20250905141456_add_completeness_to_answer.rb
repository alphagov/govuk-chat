class AddCompletenessToAnswer < ActiveRecord::Migration[8.0]
  def change
    create_enum :answer_completeness, %w[complete partial no_information]

    add_column :answers, :completeness, :answer_completeness
  end
end
