class AddAbortNoGovukContentToStatusEnum < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "abort_no_govuk_content"
  end
end
