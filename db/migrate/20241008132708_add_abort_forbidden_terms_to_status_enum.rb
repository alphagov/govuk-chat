class AddAbortForbiddenTermsToStatusEnum < ActiveRecord::Migration[7.2]
  def change
    add_enum_value :status, "abort_forbidden_terms"
  end
end
