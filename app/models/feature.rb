class Feature
  def self.enabled?(feature, user = Current.user)
    Flipper.enabled?(feature, user)
  end
end
