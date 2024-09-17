class AddErrorTimeoutAnswerStatus < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "error_timeout"
  end
end
