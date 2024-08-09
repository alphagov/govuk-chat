class SettingsAudit < ApplicationRecord
  belongs_to :user, optional: true, class_name: "AdminUser"
end
