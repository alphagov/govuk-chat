class AnswerSource < ApplicationRecord
  belongs_to :answer

  def url
    "#{Plek.website_root}#{exact_path}"
  end
end
