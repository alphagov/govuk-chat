class AddForbiddenTermsDetectedToAnswer < ActiveRecord::Migration[8.0]
  def change
    add_column :answers, :forbidden_terms_detected, :string, array: true, default: [], null: false
  end
end
