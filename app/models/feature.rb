class Feature
  def self.enabled?(feature, user = Current.user)
    return Flipper.enabled?(feature) if Current.user.nil?

    Flipper.enabled?(feature, user)
  end
end
