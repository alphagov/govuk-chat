class Question < ApplicationRecord
  belongs_to :conversation
  has_one :answer
end
