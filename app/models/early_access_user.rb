class EarlyAccessUser < ApplicationRecord
  passwordless_with :email
end
