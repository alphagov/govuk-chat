class AnswerSourceRelevancyNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :answer_sources, :relevancy, false
  end
end
