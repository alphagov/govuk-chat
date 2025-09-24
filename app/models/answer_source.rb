class AnswerSource < ApplicationRecord
  belongs_to :answer
  belongs_to :chunk,
             class_name: "AnswerSourceChunk",
             foreign_key: "answer_source_chunk_id"

  scope :used, -> { where(used: true) }
  scope :unused, -> { where(used: false) }

  def serialize_for_export
    as_json(except: :answer_source_chunk_id).merge(
      "chunk" => chunk.serialize_for_export,
    )
  end
end
