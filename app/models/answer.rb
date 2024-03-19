class Answer < ApplicationRecord
  belongs_to :question
  has_many :sources, class_name: "AnswerSource"
end
