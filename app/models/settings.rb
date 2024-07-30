class Settings < ApplicationRecord
  validates :singleton_guard, inclusion: { in: [0] }, strict: true
end
