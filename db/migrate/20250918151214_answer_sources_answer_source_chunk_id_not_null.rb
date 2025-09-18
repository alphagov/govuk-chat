class AnswerSourcesAnswerSourceChunkIdNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :answer_sources, :answer_source_chunk_id, false
  end
end
