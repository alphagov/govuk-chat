class Form::EarlyAccessEntry
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :source

  def submit
    user = EarlyAccessUser.find_or_create_by!(email:, source:)
    # check revoked status
    session = Passwordless::Session.new(authenticatable: user)
    session.save!
    EarlyAccessAuthMailer.sign_in(session).deliver_now
  end
end
