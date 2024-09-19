class DeletedEarlyAccessUser < ApplicationRecord
  enum :deletion_type, { unsubscribe: "unsubscribe", admin: "admin" }, prefix: true
  enum :registration_source, EarlyAccessUser::SOURCE_ENUM, prefix: true
end
