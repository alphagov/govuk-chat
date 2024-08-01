class Settings < ApplicationRecord
  validates :singleton_guard, inclusion: { in: [0] }, strict: true

  def self.instance
    first_or_create!
  end
end
