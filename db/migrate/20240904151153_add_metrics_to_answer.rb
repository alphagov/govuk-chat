class AddMetricsToAnswer < ActiveRecord::Migration[7.2]
  def change
    add_column :answers, :metrics, :jsonb
  end
end
