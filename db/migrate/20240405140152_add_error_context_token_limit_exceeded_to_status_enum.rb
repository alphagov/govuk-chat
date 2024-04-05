class AddErrorContextTokenLimitExceededToStatusEnum < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "error_context_length_exceeded"
  end
end
