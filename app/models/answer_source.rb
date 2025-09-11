class AnswerSource < ApplicationRecord
  belongs_to :answer
  belongs_to :chunk, class_name: "AnswerSourceChunk", optional: true

  scope :used, -> { where(used: true) }
  scope :unused, -> { where(used: false) }

  def url
    "#{Plek.website_root}#{exact_path}"
  end

  def serialize_for_export
    as_json
  end
end
