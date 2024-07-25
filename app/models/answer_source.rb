class AnswerSource < ApplicationRecord
  belongs_to :answer

  scope :used, -> { where(used: true) }

  def url
    "#{Plek.website_root}#{exact_path}"
  end
end
