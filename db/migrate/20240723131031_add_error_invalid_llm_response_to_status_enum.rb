class AddErrorInvalidLlmResponseToStatusEnum < ActiveRecord::Migration[7.1]
  def change
    add_enum_value :status, "error_invalid_llm_response"
  end
end
