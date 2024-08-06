class Form::SigninUser
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :user

  def submit
    user = EarlyAccessUser.find_by(email:)
    #check
    session = Passwordless::Session.new(authenticatable: user)
    session.save!
    SigninMailer.call(session).deliver_now
  end
end
