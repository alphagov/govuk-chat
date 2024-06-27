class AddAbortTimeoutEnumToAnswer < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "abort_timeout"
  end
end
