class AddChunksReferenceToAnswerSources < ActiveRecord::Migration[8.0]
  def change
    add_reference :answer_sources,
                  :answer_source_chunk,
                  type: :uuid,
                  foreign_key: { on_delete: :restrict }
  end
end
