class Feature
  def self.enabled?(feature, user = Current.admin_user)
    Flipper.enabled?(feature, user)
  end
end
