module StubFeatureFlags
  def stub_feature_flag(feature_name, value)
    allow(Flipper).to receive(:enabled?).with(feature_name, anything).and_return(value)
    allow(Flipper).to receive(:enabled?).with(feature_name).and_return(value)
  end

  def stub_feature_flag_for_actor(feature_name, actor, value)
    allow(Flipper).to receive(:enabled?).with(feature_name, actor).and_return(value)
  end
end
