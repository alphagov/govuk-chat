class AnswerSource < ApplicationRecord
  belongs_to :answer

  def url
    "#{Plek.website_root}#{path}"
  end
end
