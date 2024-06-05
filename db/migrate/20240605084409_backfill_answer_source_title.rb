class BackfillAnswerSourceTitle < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  class AnswerSource < ApplicationRecord; end

  def up
    AnswerSource.where(title: nil).find_each do |source|
      source.update!(title: source.path)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
